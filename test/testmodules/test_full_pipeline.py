# Full end-to-end inference test.
#
# Pipeline under test (all in main.sv):
#   mnist_loader → conv_layer1 → maxpool_l1 → conv_layer2 →
#   maxpool_l2   → conv_layer3 → classification_tree → number_o
#
# For each of N MNIST test images:
#   1. Stream the image through the hardware pipeline.
#   2. Wait for inference_done_o.
#   3. Read number_o from the DUT.
#   4. Run the identical pipeline in Python (QAE features + XGBoost trees).
#   5. Assert hardware output == Python reference prediction.
#
# Usage: run with TOPLEVEL=tb_main_full, COCOTB_TEST_MODULES=test_full_pipeline

import os
import sys

import numpy as np
import torch
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from helper_functions import dump_sram

# ---------------------------------------------------------------------------
# Path setup
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

from Model_QuantizedAE import QuantizedAE  # noqa: E402
from func.load_mnist import load_mnist     # noqa: E402

_AE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/QuantizedAE.pnn")
_MNIST_DIR  = os.path.join(_BNN_DIR, "data")

# How many MNIST test images to run end-to-end
NUM_IMAGES = 1000

# Minimum accuracy (fraction) required to pass the test
MIN_ACCURACY = 0.65

# ---------------------------------------------------------------------------
# Image helpers
# ---------------------------------------------------------------------------

def preprocess_image(model, img):
    with torch.no_grad():
        out = model.preprocess(img)
    return ((out + 1) / 2).round().numpy().astype(np.uint8).reshape(28, 28)


def image_to_packets(binary_28x28: np.ndarray) -> list:
    packets = []
    for br in range(14):
        for bc in range(0, 14, 2):
            r, c = 2 * br, 2 * bc
            p0, p1, p2, p3 = (binary_28x28[r, c],   binary_28x28[r, c+1],
                               binary_28x28[r+1, c], binary_28x28[r+1, c+1])
            low  = (p0 | (p1 << 1) | (p2 << 2) | (p3 << 3)) & 0xF
            c2   = 2 * (bc + 1)
            q0, q1, q2, q3 = (binary_28x28[r, c2],   binary_28x28[r, c2+1],
                               binary_28x28[r+1, c2], binary_28x28[r+1, c2+1])
            high = (q0 | (q1 << 1) | (q2 << 2) | (q3 << 3)) & 0xF
            packets.append(low | (high << 4))
    assert len(packets) == 98
    return packets


# ---------------------------------------------------------------------------
# Hardware helpers
# ---------------------------------------------------------------------------

async def do_reset(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value       = 0
    dut.data_in_clk.value = 0
    dut.data_in.value     = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def stream_packets(dut, packets: list):
    for pkt in packets:
        dut.data_in.value     = int(pkt)
        dut.data_in_clk.value = 1
        await ClockCycles(dut.clk, 2)
        dut.data_in_clk.value = 0
        await ClockCycles(dut.clk, 2)


def read_sram_bitmap(dut, base: int, num_channels: int, size: int) -> np.ndarray:
    mem    = dut.dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
    ch_sz  = size * size
    output = np.zeros((num_channels, size, size), dtype=np.uint8)
    for co in range(num_channels):
        for r in range(size):
            for c in range(size):
                linear   = co * ch_sz + r * size + c
                byte_idx = base + linear // 8
                bit_pos  = 7 - (linear % 8)
                raw      = str(mem[byte_idx].value)
                clean    = raw.lower().replace('x', '0').replace('z', '0')
                byte_val = int(clean, 2)
                output[co, r, c] = (byte_val >> bit_pos) & 1
    return output


def read_embedding_from_sram(dut) -> np.ndarray:
    """Read the 64-bit embedding from SRAM[245..252]."""
    mem = dut.dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
    emb = np.zeros(64, dtype=np.uint8)
    for i in range(64):
        byte_idx = 245 + i // 8
        bit_pos  = 7 - (i % 8)
        raw      = str(mem[byte_idx].value)
        clean    = raw.lower().replace('x', '0').replace('z', '0')
        byte_val = int(clean, 2)
        emb[i]   = (byte_val >> bit_pos) & 1
    return emb


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_full_pipeline(dut):
    dut._log.info("=== test_full_pipeline ===")

    # ------------------------------------------------------------------
    # Load model and XGBoost tree
    # ------------------------------------------------------------------
    model = QuantizedAE()
    model.load_state_dict(torch.load(_AE_WEIGHTS, map_location="cpu"))
    model.eval()

    _, val_loader = load_mnist(_MNIST_DIR)
    val_dataset = val_loader.dataset

    # ------------------------------------------------------------------
    # Reset once, then test NUM_IMAGES images
    # ------------------------------------------------------------------
    await do_reset(dut)
    dut._log.info("Reset done")

    # Total cycle budget: mnist_load + conv1 + pool1 + conv2 + pool2 + conv3
    # ~600 + ~1512 + ~1728 + ~1088 + ~384 + ~20 + margin
    TIMEOUT = 8000

    passed = 0
    failed = 0

    for img_idx in range(NUM_IMAGES):
        img, label = val_dataset[img_idx]
        binary_28 = preprocess_image(model, img.unsqueeze(0))
        packets   = image_to_packets(binary_28)

        # Reset DUT for fresh inference
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 3)
        dut.rst_n.value = 1
        await ClockCycles(dut.clk, 2)

        # Stream 98 MNIST packets
        await stream_packets(dut, packets)

        # Wait for inference_done_o
        hw_pred = None
        for cycle in range(TIMEOUT):
            await ClockCycles(dut.clk, 1)
            if int(dut.inference_done.value) == 1:
                hw_pred = int(dut.number_o.value)
                break
        else:
            raise AssertionError(
                f"Image {img_idx}: inference_done_o not asserted within {TIMEOUT} cycles"
            )

        # Dump SRAM on first image only
        if img_idx == 0:
            dump_path = os.path.join(
                os.path.dirname(__file__), "../sramdump/full_pipeline.dump"
            )
            dump_sram(dut.dut, dump_path)

        # Compare against true MNIST label
        if hw_pred == label:
            passed += 1
        else:
            failed += 1

        if (img_idx + 1) % 100 == 0:
            acc = passed / (img_idx + 1)
            dut._log.info(
                f"[{img_idx + 1}/{NUM_IMAGES}] accuracy so far: "
                f"{passed}/{img_idx + 1} = {acc:.1%}"
            )

        await ClockCycles(dut.clk, 5)

    # Summary
    accuracy = passed / NUM_IMAGES
    dut._log.info(
        f"=== Results: {passed}/{NUM_IMAGES} correct ({accuracy:.1%}) — "
        f"threshold {MIN_ACCURACY:.0%} ==="
    )
    assert accuracy >= MIN_ACCURACY, (
        f"Accuracy {accuracy:.1%} ({passed}/{NUM_IMAGES}) is below "
        f"the required {MIN_ACCURACY:.0%}"
    )
