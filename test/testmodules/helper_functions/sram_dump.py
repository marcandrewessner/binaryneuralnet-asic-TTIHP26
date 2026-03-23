import os


def dump_sram(dut, path: str, n_rows: int = 256) -> None:
    """
    Dump the contents of the SRAM behavioral model to a human-readable file.

    Each line shows the address and the raw 8-bit value, preserving X/Z so
    uninitialised bits are visible:

        addr 0x00 : 10110100
        addr 0x01 : 01xx1100
        addr 0x02 : xxxxxxxx
        ...

    Args:
        dut:    The cocotb DUT.  The SRAM must be accessible at the path
                dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory
        path:   Output file path.  Parent directories are created if needed.
        n_rows: How many rows to dump (default: all 256).
    """
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    mem = dut.sram.ihp_sram.i_SRAM_1P_behavioral_bm_bist.memory

    with open(path, "w") as f:
        for i in range(n_rows):
            bits = mem[i].value.binstr   # raw, keeps X and Z characters
            f.write(f"addr 0x{i:02X} : {bits}\n")
