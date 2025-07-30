# SPDX-FileCopyrightText: © 2025 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

# When submitting your design, change this to 16 + the peripheral number
# in peripherals.v.  e.g. if your design is i_user_simple00, set this to 16.
# The peripheral number is not used by the test harness.
PERIPHERAL_NUM = 16


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    BIT_CS = 3
    BIT_SD = 2
    BIT_SCK = 1
    BIT_DC = 4

    ADDR_PIXEL = 0
    ADDR_SPI = 1
    ADDR_DC_PRESC = 2
    ADDR_SEL = 8
    ADDR_STATUS = 8

    # Interact with your design's registers through this TinyQV class.
    # This will allow the same test to be run when your design is integrated
    # with TinyQV - the implementation of this class will be replaces with a
    # different version that uses Risc-V instructions instead of the SPI
    # interface to read and write the registers.
    tqv = TinyQV(dut, PERIPHERAL_NUM)

    # Reset, always start the test by resetting TinyQV
    await tqv.reset()

    dut._log.info("Waveforms behavior")

    # DC, CS, prescaler (not asserted)
    await tqv.write_reg(ADDR_DC_PRESC, 0b1_0_1100)
    assert dut.uo_out[BIT_CS].value == 1
    assert dut.uo_out[BIT_DC].value == 0

    await tqv.write_reg(ADDR_DC_PRESC, 0b0_1_1100)
    assert dut.uo_out[BIT_CS].value == 0
    assert dut.uo_out[BIT_DC].value == 1

    await tqv.write_reg(ADDR_DC_PRESC, 0b1_1_1100)

    # SPI tunnel, set CS manually
    await tqv.write_reg(ADDR_DC_PRESC, 0b0_1_0010)
    await tqv.write_reg(ADDR_SPI, 0x51)
    await tqv.write_reg(ADDR_SPI, 0x15)
    await tqv.write_reg(ADDR_DC_PRESC, 0b0_1_0010)
    await ClockCycles(dut.clk, 100)

    # Select page
    await tqv.write_reg(ADDR_SEL, 0x0)
    await ClockCycles(dut.clk, 200)

    # read status
    assert await tqv.read_reg(ADDR_STATUS) == 1
    await ClockCycles(dut.clk, 100)

    # clock pixel
    await tqv.write_reg(ADDR_PIXEL, 0xF0)
    await ClockCycles(dut.clk, 1000)

    # Set an input value, in the example this will be added to the register value
    # dut.ui_in.value = 30

    # Wait for two clock cycles to see the output values, because ui_in is synchronized over two clocks,
    # and a further clock is required for the output to propagate.
    # await ClockCycles(dut.clk, 3)

    # The following assertion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
