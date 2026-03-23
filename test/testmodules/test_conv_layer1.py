# Test for conv_layer1.
#
# Pipeline tested end-to-end:
#   1. Stream one MNIST image through mnist_loader → SRAM[0..24]
#   2. Run conv_layer1 → SRAM[25..175]
#   3. Unpack the 8×12×12 binary output and compare against an independent
#      Python reference that applies the same XNOR-popcount + majority-vote
#      logic using the trained BinaryConv2d weights.

import os
import sys
import numpy as np
import torch
import torchvision

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from helper_functions import dump_sram

from IPython import embed

# ---------------------------------------------------------------------------
# Path setup — pull in the training repo
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

from Model_QuantizedAE import QuantizedAE   # noqa: E402

_AE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/QuantizedAE.pnn")
_MNIST_DIR  = os.path.join(_BNN_DIR, "data")

# ---------------------------------------------------------------------------
# Image helpers (reused from test_mnist_loader logic)
# ---------------------------------------------------------------------------

def load_one_mnist_image(index: int = 0):
    """Return a (1,1,28,28) float tensor and its label from the MNIST test set."""
    ds = torchvision.datasets.MNIST(
        _MNIST_DIR, train=False, download=True,
        transform=torchvision.transforms.ToTensor(),
    )
    img, label = ds[index]
    return img.unsqueeze(0), label   # (1,1,28,28), int


def preprocess_image(model: QuantizedAE, img: torch.Tensor) -> np.ndarray:
    """
    Apply QuantizedAE.preprocess → (28,28) uint8 in {0,1}.
    QuantizeBinary outputs ±1; we remap −1→0, +1→1.
    """
    with torch.no_grad():
        out = model.preprocess(img)
    binary = ((out + 1) / 2).round().numpy().astype(np.uint8)
    return binary.reshape(28, 28)


def image_to_packets(binary_img: np.ndarray) -> list:
    """Pack (28,28) binary image into 98 hardware packets (same as test_mnist_loader)."""
    packets = []
    for br in range(14):
        for bc in range(0, 14, 2):
            r, c = 2 * br, 2 * bc
            p0, p1, p2, p3 = (binary_img[r, c], binary_img[r, c+1],
                               binary_img[r+1, c], binary_img[r+1, c+1])
            low = (p0 | (p1 << 1) | (p2 << 2) | (p3 << 3)) & 0xF
            c2 = 2 * (bc + 1)
            q0, q1, q2, q3 = (binary_img[r, c2], binary_img[r, c2+1],
                               binary_img[r+1, c2], binary_img[r+1, c2+1])
            high = (q0 | (q1 << 1) | (q2 << 2) | (q3 << 3)) & 0xF
            packets.append(low | (high << 4))
    assert len(packets) == 98
    return packets


def packets_to_14x14(packets: list) -> np.ndarray:
    """
    Reconstruct the 14×14 binary image (what mnist_loader stores in SRAM)
    from the 98 hardware packets.
    """
    img = np.zeros((14, 14), dtype=np.uint8)
    for i, pkt in enumerate(packets):
        pixel_1 = 1 if (pkt & 0x0F) else 0
        pixel_2 = 1 if (pkt & 0xF0) else 0
        row = (i * 2) // 14
        col = (i * 2) % 14
        img[row, col]     = pixel_1
        img[row, col + 1] = pixel_2
    return img


# ---------------------------------------------------------------------------
# Reference convolution — mirrors hardware XNOR-popcount + majority vote
# ---------------------------------------------------------------------------

def reference_conv_layer1(binary_14x14: np.ndarray,
                           model: QuantizedAE) -> np.ndarray:
    """
    Pure-Python reference for conv_layer1.

    Applies the same XNOR-popcount + majority-vote logic that the hardware
    implements, using the quantized weights from the trained model.

    Args:
        binary_14x14: (14,14) uint8 array in {0,1}
        model:        loaded QuantizedAE (weights taken from features[1])

    Returns:
        (8, 12, 12) uint8 array in {0,1}
    """
    weights_raw = model.features[1].get_parameter("weights").detach().numpy()
    # binarise: sign → {-1,+1} → {0,1}
    weights = np.where(np.sign(weights_raw) > 0, 1, 0).astype(np.uint8)  # (8,1,3,3)

    output = np.zeros((8, 12, 12), dtype=np.uint8)
    for co in range(8):
        w = weights[co, 0]   # (3,3)
        for r in range(12):
            for c in range(12):
                window   = binary_14x14[r:r+3, c:c+3]   # (3,3)
                xnor     = 1 - (window ^ w)              # 1 where they agree
                popcount = int(xnor.sum())
                output[co, r, c] = 1 if popcount >= 5 else 0
    return output


# ---------------------------------------------------------------------------
# SRAM output readback
# ---------------------------------------------------------------------------

def read_conv_output(dut, output_base: int = 25) -> np.ndarray:
    """
    Read the 8×12×12 binary output written by conv_layer1 from SRAM.

    Channel-first, MSB-first row-major layout:
      linear_idx = co*144 + row*12 + col
      byte  = output_base + linear_idx // 8
      bit   = 7 − (linear_idx % 8)
    """
    mem = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory

    output = np.zeros((8, 12, 12), dtype=np.uint8)
    for co in range(8):
        for r in range(12):
            for c in range(12):
                linear   = co * 144 + r * 12 + c
                byte_idx = output_base + linear // 8
                bit_pos  = 7 - (linear % 8)
                raw      = str(mem[byte_idx].value)
                clean    = raw.lower().replace('x', '0').replace('z', '0')
                byte_val = int(clean, 2)
                output[co, r, c] = (byte_val >> bit_pos) & 1
    return output


# ---------------------------------------------------------------------------
# Helpers: reset and packet streaming
# ---------------------------------------------------------------------------

async def do_reset(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value       = 0
    dut.data_in_clk.value = 0
    dut.data_in.value     = 0
    dut.conv_start.value  = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def stream_packets(dut, packets: list):
    """Stream 98 packets into mnist_loader and wait for done_o."""
    for pkt in packets:
        dut.data_in.value = int(pkt)
        # rising edge of data_in_clk
        dut.data_in_clk.value = 1
        await ClockCycles(dut.clk, 2)
        # falling edge
        dut.data_in_clk.value = 0
        await ClockCycles(dut.clk, 2)

    # wait for done
    for _ in range(50):
        await ClockCycles(dut.clk, 1)
        if dut.mnist_done.value == 1:
            return
    raise AssertionError("mnist_loader did not assert done_o within timeout")


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_conv_layer1(dut):
    dut._log.info("=== test_conv_layer1 ===")

    # ------------------------------------------------------------------
    # 0. Load model and prepare image
    # ------------------------------------------------------------------
    model = QuantizedAE()
    model.load_state_dict(torch.load(_AE_WEIGHTS, map_location="cpu"))
    model.eval()

    img, label = load_one_mnist_image(index=0)
    dut._log.info(f"MNIST image label: {label}")

    binary_28x28 = preprocess_image(model, img)
    packets      = image_to_packets(binary_28x28)
    binary_14x14 = packets_to_14x14(packets)

    dut._log.info(
        f"14×14 image — active pixels: {int(binary_14x14.sum())} / 196"
    )

    # ------------------------------------------------------------------
    # 1. Reset
    # ------------------------------------------------------------------
    await do_reset(dut)
    dut._log.info("Reset done")

    # ------------------------------------------------------------------
    # 2. Phase 1: stream MNIST image into SRAM via mnist_loader
    # ------------------------------------------------------------------
    dut._log.info("Streaming 98 packets into mnist_loader ...")
    await stream_packets(dut, packets)
    await ClockCycles(dut.clk, 2)
    dut._log.info("mnist_loader done")

    # ------------------------------------------------------------------
    # 3. Phase 2: run conv_layer1
    # ------------------------------------------------------------------
    dut._log.info("Starting conv_layer1 ...")
    dut.conv_start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.conv_start.value = 0

    # Worst-case: 36 windows × 42 cycles + margin = 1700 cycles
    TIMEOUT = 1700
    for cycle in range(TIMEOUT):
        await ClockCycles(dut.clk, 1)
        if dut.conv_done.value == 1:
            dut._log.info(f"conv_layer1 done after {cycle + 1} cycles")
            break
    else:
        raise AssertionError(
            f"conv_layer1 did not assert done_o within {TIMEOUT} cycles"
        )

    await ClockCycles(dut.clk, 2)

    # ------------------------------------------------------------------
    # 4. Read hardware output from SRAM
    # ------------------------------------------------------------------
    hw_output = read_conv_output(dut, output_base=25)
    dut._log.info(
        f"Hardware output — active bits: {int(hw_output.sum())} / {8*12*12}"
    )

    # Dump full SRAM for inspection
    dump_path = os.path.join(
        os.path.dirname(__file__), "../sramdump/conv_layer1.dump"
    )
    dump_sram(dut, dump_path)
    dut._log.info(f"SRAM dump → {dump_path}")

    # ------------------------------------------------------------------
    # 5. Compute reference output (Python XNOR-popcount + majority vote)
    # ------------------------------------------------------------------
    ref_output = reference_conv_layer1(binary_14x14, model)
    dut._log.info(
        f"Reference output — active bits: {int(ref_output.sum())} / {8*12*12}"
    )

    # ------------------------------------------------------------------
    # 6. Compare
    # ------------------------------------------------------------------
    mismatches = int(np.sum(hw_output != ref_output))
    total      = 8 * 12 * 12   # = 1152

    if mismatches > 0:
        # Print per-channel breakdown to aid debugging
        for co in range(8):
            ch_mm = int(np.sum(hw_output[co] != ref_output[co]))
            if ch_mm:
                dut._log.error(
                    f"  channel {co}: {ch_mm} mismatches out of 144"
                )
                # Show first few bad positions
                ys, xs = np.where(hw_output[co] != ref_output[co])
                for y, x in zip(ys[:5], xs[:5]):
                    dut._log.error(
                        f"    (row={y}, col={x}): hw={hw_output[co,y,x]} "
                        f"ref={ref_output[co,y,x]}"
                    )
        assert False, (
            f"conv_layer1 output mismatch: {mismatches}/{total} bits wrong"
        )

    dut._log.info(
        f"All {total} output bits match the reference — PASSED"
    )
