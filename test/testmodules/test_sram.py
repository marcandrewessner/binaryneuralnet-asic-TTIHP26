# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# ---------------------------------------------------------------------------
# sram_req_t packed struct layout (26 bits, MSB→LSB as declared):
#   addr [7:0]  → bits [25:18]
#   bm   [7:0]  → bits [17:10]
#   wen         → bit  [9]
#   ren         → bit  [8]
#   din  [7:0]  → bits [7:0]
# ---------------------------------------------------------------------------

def pack_req(addr=0, bm=0xFF, wen=0, ren=0, din=0):
    return (addr & 0xFF) << 18 | (bm & 0xFF) << 10 | (wen & 1) << 9 | (ren & 1) << 8 | (din & 0xFF)

def unpack_dout(sram_rsp):
    # sram_rsp_t has a single field: dout [7:0]
    return int(sram_rsp.value) & 0xFF


async def sram_write(dut, addr, data, bm=0xFF):
    dut.sram_req.value = pack_req(addr=addr, bm=bm, wen=1, ren=0, din=data)
    await ClockCycles(dut.clk, 1)
    dut.sram_req.value = pack_req()  # deassert


async def sram_read(dut, addr):
    dut.sram_req.value = pack_req(addr=addr, ren=1)
    await ClockCycles(dut.clk, 1)
    dut.sram_req.value = pack_req()  # deassert
    await ClockCycles(dut.clk, 1)   # wait for output register
    return unpack_dout(dut.sram_rsp)


@cocotb.test()
async def test_sram(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 0
    dut.sram_req.value = pack_req()
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # --- Write a batch of values ---
    dut._log.info("Writing 5 values")
    writes = {
        0x00: 0xAB,
        0x01: 0x10,
        0x02: 0x42,
        0x7F: 0xFF,
        0xFF: 0x5A,
    }
    for addr, data in writes.items():
        await sram_write(dut, addr, data)

    # --- Read them back and verify ---
    dut._log.info("Reading back written values")
    for addr, expected in writes.items():
        got = await sram_read(dut, addr)
        assert got == expected, f"addr=0x{addr:02X}: expected 0x{expected:02X}, got 0x{got:02X}"
        dut._log.info(f"  addr=0x{addr:02X} -> 0x{got:02X} OK")

    # --- Overwrite one address and confirm the new value ---
    dut._log.info("Overwriting addr 0x01: 0x10 -> 0xBE")
    await sram_write(dut, 0x01, 0xBE)
    got = await sram_read(dut, 0x01)
    assert got == 0xBE, f"after overwrite: expected 0xBE, got 0x{got:02X}"
    dut._log.info(f"  addr=0x01 -> 0x{got:02X} OK")

    # --- Confirm other addresses are untouched ---
    dut._log.info("Re-reading other addresses to confirm no corruption")
    for addr, expected in writes.items():
        if addr == 0x01:
            continue
        got = await sram_read(dut, addr)
        assert got == expected, f"addr=0x{addr:02X} corrupted: expected 0x{expected:02X}, got 0x{got:02X}"
        dut._log.info(f"  addr=0x{addr:02X} -> 0x{got:02X} OK")

    dut._log.info("All tests passed!")
