# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from helper_functions import load_sram_from_array, load_sram_from_dump, dump_sram


# ---------------------------------------------------------------------------
# Helper: pack a 2-D binary image into SRAM bytes (MSB-first, row-major).
#
# Pixel at (row, col) in an image of any shape:
#   linear index p = row * image_width + col
#   SRAM byte      = p // 8
#   bit within byte = 7 - (p % 8)   ← bit[7] is the first (MSB) pixel
# ---------------------------------------------------------------------------

def pack_image_to_sram(image: np.ndarray) -> np.ndarray:
    """
    Pack a 2-D binary image (dtype uint8, values in {0,1}) into SRAM bytes.
    Returns a 1-D uint8 array of length ceil(rows*cols / 8).
    """
    flat    = image.flatten()
    n_bytes = (len(flat) + 7) // 8
    out     = np.zeros(n_bytes, dtype=np.uint8)
    for i, px in enumerate(flat):
        byte_idx = i // 8
        bit_idx  = 7 - (i % 8)
        out[byte_idx] |= (int(px) & 1) << bit_idx
    return out


# ---------------------------------------------------------------------------
# Helper: compute the expected 18-bit buffer for a 3×6 window.
#
# buffer_o layout:
#   [17:12] = row 0, pixels 0..5   (bit 17 = pixel (row, col))
#   [11:6]  = row 1, pixels 0..5
#   [5:0]   = row 2, pixels 0..5   (bit 0  = pixel (row+2, col+5))
# ---------------------------------------------------------------------------

def expected_buffer(image: np.ndarray, row: int, col: int) -> int:
    result = 0
    for r in range(3):
        for c in range(6):
            pixel   = int(image[row + r, col + c])
            bit_pos = 17 - r * 6 - c
            result |= pixel << bit_pos
    return result


# ---------------------------------------------------------------------------
# Reset helper
# ---------------------------------------------------------------------------

async def do_reset(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value          = 0
    dut.read_en.value        = 0
    dut.stride.value         = 0
    dut.data_pointer.value   = 0
    dut.data_bit_offset.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Trigger a single load and return (ready_cycles_waited, buffer_value).
# read_en_i is pulsed for 1 cycle then deasserted.
# ---------------------------------------------------------------------------

async def run_load(dut, stride, data_pointer, data_bit_offset, timeout=20):
    dut.stride.value          = stride
    dut.data_pointer.value    = data_pointer
    dut.data_bit_offset.value = data_bit_offset

    dut.read_en.value = 1
    await ClockCycles(dut.clk, 1)
    dut.read_en.value = 0

    for cycle in range(timeout):
        await ClockCycles(dut.clk, 1)
        if dut.ready.value == 1:
            return cycle + 1, int(dut.buffer.value)

    raise AssertionError(f"ready_o did not assert within {timeout} cycles")


# ---------------------------------------------------------------------------
# Test 1: byte-aligned window at (row=0, col=0) on a 14-wide image
# data_pointer=0, data_bit_offset=0 → first 6 pixels of each of 3 rows.
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_aligned(dut):
    dut._log.info("Start: test_aligned")

    await do_reset(dut)

    # Fixed known pattern: every other pixel active
    image = np.zeros((14, 14), dtype=np.uint8)
    image[0, :] = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
    image[1, :] = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
    image[2, :] = [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]

    sram_bytes = pack_image_to_sram(image)
    load_sram_from_array(dut, sram_bytes)
    dut._log.info(f"  Loaded {len(sram_bytes)} bytes into SRAM")

    exp = expected_buffer(image, row=0, col=0)
    cycles, got = await run_load(dut, stride=14, data_pointer=0, data_bit_offset=0)

    dut._log.info(f"  Ready after {cycles} cycles")
    dut._log.info(f"  Expected: 0b{exp:018b}")
    dut._log.info(f"  Got:      0b{got:018b}")
    assert got == exp, f"Mismatch: expected 0b{exp:018b}, got 0b{got:018b}"
    dut._log.info("  test_aligned PASSED ✓")

    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Test 2: unaligned window — row=1, col=4 of a 14-wide image
# start_bit = 1*14 + 4 = 18  → data_pointer=0, data_bit_offset=18
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_unaligned(dut):
    dut._log.info("Start: test_unaligned")

    await do_reset(dut)

    rng   = np.random.default_rng(seed=42)
    image = rng.integers(0, 2, size=(14, 14), dtype=np.uint8)

    sram_bytes = pack_image_to_sram(image)
    load_sram_from_array(dut, sram_bytes)

    stride         = 14
    row, col       = 1, 4
    start_bit      = row * stride + col       # = 18
    data_pointer   = 0
    data_bit_offset = start_bit               # bit offset from byte 0

    exp = expected_buffer(image, row=row, col=col)
    cycles, got = await run_load(dut, stride=stride,
                                 data_pointer=data_pointer,
                                 data_bit_offset=data_bit_offset)

    dut._log.info(f"  Window (r={row}, c={col}), start_bit={start_bit}")
    dut._log.info(f"  Ready after {cycles} cycles")
    dut._log.info(f"  Expected: 0b{exp:018b}")
    dut._log.info(f"  Got:      0b{got:018b}")
    assert got == exp, f"Mismatch: expected 0b{exp:018b}, got 0b{got:018b}"
    dut._log.info("  test_unaligned PASSED ✓")

    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Test 3: sweep across all valid 3×6 window positions in a 14×14 image
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_sweep_all_windows(dut):
    dut._log.info("Start: test_sweep_all_windows")

    await do_reset(dut)

    rng   = np.random.default_rng(seed=99)
    image = rng.integers(0, 2, size=(14, 14), dtype=np.uint8)

    sram_bytes = pack_image_to_sram(image)
    load_sram_from_array(dut, sram_bytes)

    stride   = 14
    failures = []

    for row in range(14 - 3 + 1):      # rows 0..11
        for col in range(14 - 6 + 1):  # cols 0..8
            start_bit = row * stride + col
            exp       = expected_buffer(image, row=row, col=col)

            _, got = await run_load(dut, stride=stride,
                                    data_pointer=0,
                                    data_bit_offset=start_bit)

            if got != exp:
                failures.append((row, col, exp, got))
                dut._log.error(
                    f"  FAIL (r={row},c={col}): "
                    f"expected 0b{exp:018b}, got 0b{got:018b}"
                )

    if failures:
        assert False, f"{len(failures)} window(s) failed out of {12*9}"

    dut._log.info(f"  All {12 * 9} windows passed ✓")

    # Write a SRAM dump for inspection
    dump_path = os.path.join(
        os.path.dirname(__file__), "../sramdump/load_conv_op.dump"
    )
    dump_sram(dut, dump_path)
    dut._log.info(f"  SRAM dump written → {dump_path}")

    dut._log.info("All tests passed!")


# ---------------------------------------------------------------------------
# Test 4: data_pointer ≠ 0 — image starts at a non-zero SRAM byte address.
# The address arithmetic data_pointer + start_bit/8 is exercised here.
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_nonzero_pointer(dut):
    dut._log.info("Start: test_nonzero_pointer")

    await do_reset(dut)

    rng    = np.random.default_rng(seed=7)
    image  = rng.integers(0, 2, size=(14, 14), dtype=np.uint8)
    packed = pack_image_to_sram(image)    # 25 bytes

    # Write image at SRAM offset 32 (leaves bytes 0..31 at 0)
    OFFSET = 32
    load_sram_from_array(dut, packed, offset=OFFSET)
    dut._log.info(f"  Image loaded at SRAM byte offset {OFFSET}")

    stride   = 14
    failures = []

    # Sweep a subset of windows: 4 rows × 4 cols (covers several bit_off values)
    for row in range(4):
        for col in range(4):
            start_bit = row * stride + col
            # With data_pointer=OFFSET and data_bit_offset=start_bit,
            # addr_a0 = OFFSET + start_bit//8  — same pixels as pointer=0
            exp = expected_buffer(image, row=row, col=col)

            _, got = await run_load(dut, stride=stride,
                                    data_pointer=OFFSET,
                                    data_bit_offset=start_bit)

            if got != exp:
                failures.append((row, col, exp, got))
                dut._log.error(
                    f"  FAIL (r={row},c={col}): "
                    f"expected 0b{exp:018b}, got 0b{got:018b}"
                )

    assert not failures, f"{len(failures)} window(s) failed"
    dut._log.info("  test_nonzero_pointer PASSED ✓")
    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Test 5: ready_o is exactly 1 cycle wide.
# After ready fires, it must be 0 on the very next cycle (no extended pulse).
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_ready_pulse_width(dut):
    dut._log.info("Start: test_ready_pulse_width")

    await do_reset(dut)

    # All-ones image: any window should return 0x3FFFF
    sram_bytes = np.full(25, 0xFF, dtype=np.uint8)
    load_sram_from_array(dut, sram_bytes)

    dut.stride.value          = 14
    dut.data_pointer.value    = 0
    dut.data_bit_offset.value = 0

    dut.read_en.value = 1
    await ClockCycles(dut.clk, 1)
    dut.read_en.value = 0

    # Wait for ready
    for _ in range(20):
        await ClockCycles(dut.clk, 1)
        if dut.ready.value == 1:
            break
    else:
        assert False, "ready_o never asserted"

    assert int(dut.buffer.value) == 0x3FFFF, \
        f"Expected all-ones buffer, got 0x{int(dut.buffer.value):05X}"
    dut._log.info("  ready_o asserted, buffer = all-ones ✓")

    # ready_o must drop on the VERY NEXT cycle
    await ClockCycles(dut.clk, 1)
    assert dut.ready.value == 0, \
        f"ready_o stayed high for more than 1 cycle (got {dut.ready.value})"
    dut._log.info("  ready_o cleared after 1 cycle ✓")

    # buffer_o must still hold its value after ready drops
    assert int(dut.buffer.value) == 0x3FFFF, \
        "buffer_o changed after ready_o dropped"
    dut._log.info("  buffer_o stable after ready drop ✓")

    dut._log.info("  test_ready_pulse_width PASSED ✓")
    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Test 6: stride ≠ 14 — verifies the 2*stride row-offset arithmetic.
# Uses a 16-wide image (stride=16), exercises a different row spacing.
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_stride16(dut):
    dut._log.info("Start: test_stride16")

    await do_reset(dut)

    # 5-row × 16-col image (need at least 3 rows for the window)
    rng   = np.random.default_rng(seed=55)
    image = rng.integers(0, 2, size=(5, 16), dtype=np.uint8)
    packed = pack_image_to_sram(image)
    load_sram_from_array(dut, packed)

    stride   = 16
    failures = []

    # All valid 3×6 windows: rows 0..2, cols 0..10
    for row in range(5 - 3 + 1):
        for col in range(16 - 6 + 1):
            start_bit = row * stride + col
            exp       = expected_buffer(image, row=row, col=col)

            _, got = await run_load(dut, stride=stride,
                                    data_pointer=0,
                                    data_bit_offset=start_bit)

            if got != exp:
                failures.append((row, col, exp, got))
                dut._log.error(
                    f"  FAIL stride=16 (r={row},c={col}): "
                    f"expected 0b{exp:018b}, got 0b{got:018b}"
                )

    assert not failures, f"{len(failures)} window(s) failed"
    dut._log.info(f"  All {3 * 11} stride=16 windows passed ✓")
    dut._log.info("  test_stride16 PASSED ✓")
    await ClockCycles(dut.clk, 2)


# ---------------------------------------------------------------------------
# Test 7: explicit bit-offset sweep — deterministic single-pixel images.
# For each bit_off in 0..7: place exactly one '1' at pixel (0, bit_off),
# then load the window at (row=0, col=0).  Only bit (17 - bit_off) should
# be set in buffer_o.  This isolates each bit-path through extract6.
# ---------------------------------------------------------------------------

@cocotb.test()
async def test_explicit_bit_offsets(dut):
    dut._log.info("Start: test_explicit_bit_offsets")

    await do_reset(dut)

    stride = 14

    for bit_off in range(8):
        # Image with a single 1 at pixel (0, bit_off).
        # Window starts at data_bit_offset=bit_off so that pixel (0, bit_off) is
        # the FIRST pixel of the window → it must land in buffer_o[17].
        image             = np.zeros((14, 14), dtype=np.uint8)
        image[0, bit_off] = 1

        packed = pack_image_to_sram(image)
        load_sram_from_array(dut, packed)

        # data_bit_offset=bit_off: window row 0 starts exactly at SRAM bit bit_off,
        # so bit_off_r0 = bit_off inside extract6.
        _, got = await run_load(dut, stride=stride,
                                data_pointer=0, data_bit_offset=bit_off)

        # First pixel of row 0 is 1, all others are 0 → only buffer_o[17] set.
        exp = 1 << 17

        assert got == exp, (
            f"bit_off={bit_off}: expected 0b{exp:018b} "
            f"(only bit 17 set), got 0b{got:018b}"
        )
        dut._log.info(f"  bit_off={bit_off}: buffer_o[17]=1 ✓")

    dut._log.info("  test_explicit_bit_offsets PASSED ✓")
    await ClockCycles(dut.clk, 2)
