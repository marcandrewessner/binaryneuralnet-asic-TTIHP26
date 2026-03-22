# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")

  # Set the clock period to 10 us (100 KHz)
  clock = Clock(dut.clk, 10, unit="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.data.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 1)  

  for cycle in range(100):
    expected_value = cycle%2**4
    measured_value = dut.data.value.integer
    assert expected_value == measured_value, f"expected {expected_value}, got {measured_value}, in cycle {cycle}"
    await ClockCycles(dut.clk, 1)