# Test for maxpool_2x2 configured as layer-1 max-pool.
#
# Pipeline:
#   1. Load conv_layer1.dump into SRAM (pre-computed by test_conv_layer1).
#   2. Pulse start; maxpool reads SRAM[25..168], writes SRAM[169..204].
#   3. Unpack 8×6×6 result and compare against Python reference:
#        ref[co,r,c] = in[co,2r,2c] | in[co,2r,2c+1] | in[co,2r+1,2c] | in[co,2r+1,2c+1]

import os
import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from helper_functions import load_sram_from_dump, dump_sram

# ---------------------------------------------------------------------------
# Constants — must match maxpool_2x2 parameters in tb_maxpool_layer1.sv
# ---------------------------------------------------------------------------
NUM_CHANNELS = 8
IN_SIZE      = 12
OUT_SIZE     = IN_SIZE // 2   # 6
INPUT_BASE   = 25
OUTPUT_BASE  = 169

_DUMP_PATH = os.path.join(
    os.path.dirname(__file__), "../sramdump/conv_layer1.dump"
)


# ---------------------------------------------------------------------------
# SRAM readback helpers
# ---------------------------------------------------------------------------

def read_bitmap(dut, base: int, num_channels: int, size: int) -> np.ndarray:
    """
    Read a (num_channels, size, size) binary array from SRAM.
    Layout: channel-first, MSB-first row-major.
    """
    mem    = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
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


# ---------------------------------------------------------------------------
# Python reference maxpool (2×2 stride-2, OR = max for binary)
# ---------------------------------------------------------------------------

def reference_maxpool(inp: np.ndarray) -> np.ndarray:
    """
    inp:  (C, H, W) uint8 in {0,1}
    Returns (C, H//2, W//2) uint8 in {0,1}
    """
    C, H, W = inp.shape
    out = np.zeros((C, H // 2, W // 2), dtype=np.uint8)
    for co in range(C):
        for r in range(H // 2):
            for c in range(W // 2):
                out[co, r, c] = (
                    inp[co, 2*r,   2*c  ] |
                    inp[co, 2*r,   2*c+1] |
                    inp[co, 2*r+1, 2*c  ] |
                    inp[co, 2*r+1, 2*c+1]
                )
    return out


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_maxpool_layer1(dut):
    dut._log.info("=== test_maxpool_layer1 ===")

    # ------------------------------------------------------------------
    # 0. Check the dump exists
    # ------------------------------------------------------------------
    if not os.path.exists(_DUMP_PATH):
        raise FileNotFoundError(
            f"conv_layer1.dump not found at {_DUMP_PATH}. "
            "Run test_conv_layer1 first to generate it."
        )

    # ------------------------------------------------------------------
    # 1. Reset
    # ------------------------------------------------------------------
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    dut.start.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # ------------------------------------------------------------------
    # 2. Pre-load SRAM from conv_layer1 dump
    # ------------------------------------------------------------------
    dut._log.info(f"Loading SRAM from {_DUMP_PATH} ...")
    load_sram_from_dump(dut, _DUMP_PATH)
    await ClockCycles(dut.clk, 2)
    dut._log.info("SRAM loaded")

    # ------------------------------------------------------------------
    # 3. Read back conv_layer1 input from SRAM to build reference
    # ------------------------------------------------------------------
    conv_output = read_bitmap(dut, INPUT_BASE, NUM_CHANNELS, IN_SIZE)
    dut._log.info(
        f"Conv-layer1 output (from SRAM) — active bits: "
        f"{int(conv_output.sum())} / {NUM_CHANNELS * IN_SIZE * IN_SIZE}"
    )

    # ------------------------------------------------------------------
    # 4. Run maxpool
    # ------------------------------------------------------------------
    dut._log.info("Starting maxpool_layer1 ...")
    dut.start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start.value = 0

    # Worst-case: 8ch × 36 px × 6 cycles + margin = 1800 cycles
    TIMEOUT = 1800
    for cycle in range(TIMEOUT):
        await ClockCycles(dut.clk, 1)
        if dut.done.value == 1:
            dut._log.info(f"maxpool_layer1 done after {cycle + 1} cycles")
            break
    else:
        raise AssertionError(
            f"maxpool_layer1 did not assert done within {TIMEOUT} cycles"
        )

    await ClockCycles(dut.clk, 2)

    # ------------------------------------------------------------------
    # 5. Read hardware output from SRAM
    # ------------------------------------------------------------------
    hw_output = read_bitmap(dut, OUTPUT_BASE, NUM_CHANNELS, OUT_SIZE)
    dut._log.info(
        f"Hardware output — active bits: "
        f"{int(hw_output.sum())} / {NUM_CHANNELS * OUT_SIZE * OUT_SIZE}"
    )

    # Dump SRAM for inspection
    dump_path = os.path.join(
        os.path.dirname(__file__), "../sramdump/maxpool_layer1.dump"
    )
    dump_sram(dut, dump_path)
    dut._log.info(f"SRAM dump → {dump_path}")

    # ------------------------------------------------------------------
    # 6. Compare against Python reference
    # ------------------------------------------------------------------
    ref_output = reference_maxpool(conv_output)
    dut._log.info(
        f"Reference output — active bits: "
        f"{int(ref_output.sum())} / {NUM_CHANNELS * OUT_SIZE * OUT_SIZE}"
    )

    mismatches = int(np.sum(hw_output != ref_output))
    total      = NUM_CHANNELS * OUT_SIZE * OUT_SIZE  # 288

    if mismatches > 0:
        for co in range(NUM_CHANNELS):
            ch_mm = int(np.sum(hw_output[co] != ref_output[co]))
            if ch_mm:
                dut._log.error(f"  channel {co}: {ch_mm} mismatches out of {OUT_SIZE*OUT_SIZE}")
                ys, xs = np.where(hw_output[co] != ref_output[co])
                for y, x in zip(ys[:5], xs[:5]):
                    dut._log.error(
                        f"    (row={y}, col={x}): hw={hw_output[co,y,x]} "
                        f"ref={ref_output[co,y,x]}"
                    )
        assert False, f"maxpool_layer1: {mismatches}/{total} bits wrong"

    dut._log.info(f"All {total} output bits match the reference — PASSED")
