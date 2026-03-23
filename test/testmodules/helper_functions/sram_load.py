import os
import numpy as np


def load_sram_from_array(dut, data, offset: int = 0) -> None:
    """
    Preload the SRAM behavioral model from a numpy array or plain list of bytes.

    Args:
        dut:    The cocotb DUT.  The SRAM must be accessible at
                dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
        data:   1-D array-like of uint8 values (numpy array or Python list).
                Each element maps to one SRAM byte.
        offset: Starting SRAM address (default 0).
    """
    mem = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
    for i, byte in enumerate(data):
        mem[offset + i].value = int(byte) & 0xFF


def load_sram_from_dump(dut, path: str) -> None:
    """
    Load SRAM contents from a dump file previously created by dump_sram().

    Expected line format (X/Z treated as 0):
        addr 0xAB : 10110100

    Args:
        dut:  The cocotb DUT (same SRAM path as load_sram_from_array).
        path: Path to the dump file.
    """
    mem = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # "addr 0xAB : BBBBBBBB"
            addr_part, bits_part = line.split(":")
            addr = int(addr_part.split()[1], 16)
            bits = bits_part.strip().lower().replace("x", "0").replace("z", "0")
            mem[addr].value = int(bits, 2)
