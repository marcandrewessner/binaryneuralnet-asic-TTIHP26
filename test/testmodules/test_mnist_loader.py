# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import sys
import os
import numpy as np
import torch
import torchvision

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from helper_functions import dump_sram

# ---------------------------------------------------------------------------
# Path setup — pull in the training repo
# ---------------------------------------------------------------------------
_BNN_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../bnn_mnist_training")
)
if _BNN_DIR not in sys.path:
    sys.path.insert(0, _BNN_DIR)

from Model_QuantizedAE import QuantizedAE   # noqa: E402  (after sys.path fix)

_AE_WEIGHTS = os.path.join(_BNN_DIR, "data/model_weights/QuantizedAE.pnn")
_MNIST_DIR  = os.path.join(_BNN_DIR, "data")

# ---------------------------------------------------------------------------
# Preprocessing helpers
# ---------------------------------------------------------------------------

def load_one_mnist_image(index: int = 0):
    """Return a (1, 1, 28, 28) float tensor from the MNIST test set."""
    ds = torchvision.datasets.MNIST(
        _MNIST_DIR,
        train=False,
        download=True,
        transform=torchvision.transforms.ToTensor(),
    )
    img, label = ds[index]
    return img.unsqueeze(0), label   # (1,1,28,28), int


def preprocess_image(model: QuantizedAE, img: torch.Tensor) -> np.ndarray:
    """
    Apply QuantizedAE.preprocess (LearnableShift + QuantizeBinary) and return
    a (28, 28) numpy array of uint8 values in {0, 1}.

    QuantizeBinary outputs {-1, +1} (torch.sign).  We remap to {0, 1}:
      -1  →  0  (inactive pixel)
      +1  →  1  (active pixel)
    """
    with torch.no_grad():
        out = model.preprocess(img)           # {-1.0, 0.0, +1.0}
    # (-1 + 1) / 2  maps  -1→0, 0→0.5→0, +1→1  — correct for hardware
    binary = ((out + 1) / 2).round().numpy().astype(np.uint8)
    return binary.reshape(28, 28)


def image_to_packets(binary_img: np.ndarray) -> list:
    """
    Pack a (28,28) binary image into 98 hardware packets.

    Each packet byte:
      bits [3:0] = 4 pixels of one 2×2 block  (OR-pooled by hw to pixel_1)
      bits [7:4] = 4 pixels of next 2×2 block  (OR-pooled by hw to pixel_2)

    Block ordering: row-major over the 14×14 grid of 2×2 blocks,
    two columns (blocks) packed per packet.
    """
    packets = []
    for br in range(14):          # block row (0..13)
        for bc in range(0, 14, 2):    # block col, step 2 (two blocks per packet)
            r, c = 2 * br, 2 * bc

            # Lower nibble: 2×2 block at (br, bc)
            p0, p1, p2, p3 = (binary_img[r, c], binary_img[r, c+1],
                              binary_img[r+1, c], binary_img[r+1, c+1])
            low  = (p0 | (p1 << 1) | (p2 << 2) | (p3 << 3)) & 0xF

            # Upper nibble: 2×2 block at (br, bc+1)
            c2 = 2 * (bc + 1)
            q0, q1, q2, q3 = (binary_img[r, c2], binary_img[r, c2+1],
                              binary_img[r+1, c2], binary_img[r+1, c2+1])
            high = (q0 | (q1 << 1) | (q2 << 2) | (q3 << 3)) & 0xF

            packets.append(low | (high << 4))

    assert len(packets) == 98
    return packets


def packets_to_expected_sram(packets: list) -> list:
    """
    Simulate the hardware SRAM packing logic in Python to produce the
    expected contents of SRAM addresses 0..24 after all 98 packets.

      pixel_1 = |pkt[3:0]   (hw: |data_in[3:0])
      pixel_2 = |pkt[7:4]   (hw: |data_in[7:4])
      addr  = packet_index >> 2
      shift = (packet_index % 4) * 2       → 0, 2, 4, 6
      bm    = 0b11000000 >> shift
      data  = {pixel_1, pixel_2, 6'b0} >> shift

    The SRAM write applies the bitmask:
      mem[addr] = (mem[addr] & ~bm) | (data & bm)
    """
    sram = [0] * 256
    for i, pkt in enumerate(packets):
        pixel_1 = 1 if (pkt & 0x0F) != 0 else 0
        pixel_2 = 1 if (pkt & 0xF0) != 0 else 0

        addr  = i >> 2
        shift = (i % 4) * 2
        bm    = (0b11000000 >> shift) & 0xFF
        data  = (((pixel_1 << 7) | (pixel_2 << 6)) >> shift) & 0xFF

        sram[addr] = (sram[addr] & (~bm & 0xFF)) | (data & bm)

    return sram


# ---------------------------------------------------------------------------
# SRAM readback via hierarchical reference to the behavioral model's memory
# ---------------------------------------------------------------------------

def read_sram_memory(dut, n_bytes: int = 25) -> list:
    """Read n_bytes from the SRAM behavioral model's internal memory array.

    Unwritten bits are 'X' in simulation (bitmask writes leave unmasked bits
    uninitialised).  We treat X/Z as 0, matching the Python reference which
    initialises every byte to 0 and only writes the masked bits.
    """
    mem = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
    result = []
    for i in range(n_bytes):
        binstr = mem[i].value.binstr                          # e.g. "10xx0011"
        clean  = binstr.lower().replace("x", "0").replace("z", "0")
        result.append(int(clean, 2))
    return result


# ---------------------------------------------------------------------------
# Cocotb test
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_mnist_loader(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # --- Reset ---
    dut.rst_n.value       = 0
    dut.data_in_clk.value = 0
    dut.data_in.value     = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --- Preprocess one MNIST image with QuantizedAE ---
    dut._log.info("Loading QuantizedAE weights and preprocessing MNIST image")
    model = QuantizedAE()
    model.load_state_dict(torch.load(_AE_WEIGHTS, weights_only=True, map_location="cpu"))
    model.eval()

    img, label = load_one_mnist_image(index=0)
    dut._log.info(f"  Image label: {label}")

    binary_img = preprocess_image(model, img)
    active_px  = int(binary_img.sum())
    dut._log.info(f"  Binary pixels: {active_px}/784 active after preprocessing")

    packets = image_to_packets(binary_img)
    expected_sram = packets_to_expected_sram(packets)
    dut._log.info(f"  Packets: {len(packets)}, non-zero SRAM bytes: {sum(b != 0 for b in expected_sram[:25])}/25")

    # --- Stream packets into the DUT ---
    dut._log.info("Streaming 98 packets into mnist_loader")
    for i, pkt in enumerate(packets):
        dut.data_in.value = int(pkt)
        await ClockCycles(dut.clk, 1)     # let data settle

        dut.data_in_clk.value = 1         # rising edge → triggers write
        await ClockCycles(dut.clk, 2)     # hold high for ≥1 full clk_i period

        dut.data_in_clk.value = 0         # falling edge → FSM back to CLK_IN_LOW
        await ClockCycles(dut.clk, 1)     # settle before next packet

    # Wait for done flag
    await ClockCycles(dut.clk, 2)
    assert dut.done.value == 1, "done_o did not assert after 98 packets"
    dut._log.info("  done_o asserted ✓")

    # --- Verify SRAM contents ---
    dut._log.info("Verifying SRAM contents against Python reference")
    sram_actual = read_sram_memory(dut, n_bytes=25)

    mismatches = []
    for addr in range(25):
        got      = sram_actual[addr]
        expected = expected_sram[addr]
        if got != expected:
            mismatches.append((addr, expected, got))

    if mismatches:
        for addr, exp, got in mismatches:
            dut._log.error(f"  addr=0x{addr:02X}: expected 0b{exp:08b}, got 0b{got:08b}")
        assert False, f"{len(mismatches)} SRAM byte(s) did not match"

    dut._log.info("  All 25 SRAM bytes match ✓")

    # --- Dump full SRAM to file ---
    dump_path = os.path.join(os.path.dirname(__file__), "../sramdump/mnist_loader.dump")
    dump_sram(dut, dump_path)
    dut._log.info(f"  SRAM dump written → {dump_path}")

    # --- Sanity: print the 14×14 OR-pooled result ---
    pooled = np.zeros((14, 14), dtype=np.uint8)
    for i, pkt in enumerate(packets):
        br = (i // 7)
        bc = (i %  7) * 2
        pooled[br, bc]   = 1 if (pkt & 0x0F) != 0 else 0
        pooled[br, bc+1] = 1 if (pkt & 0xF0) != 0 else 0

    dut._log.info(f"  14×14 OR-pooled image (label={label}):")
    for row in pooled:
        dut._log.info("    " + "".join("█" if p else "·" for p in row))

    dut._log.info("All tests passed!")
