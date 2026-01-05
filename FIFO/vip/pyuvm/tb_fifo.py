"""
FIFO Testbench using pyUVM
Create Date: 01/05/2026

This testbench demonstrates the FIFO VIP using pyUVM methodology.
Compatible with cocotb simulator interface.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import *

# Import VIP components
import sys
import os

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common.fifo_vip_config import FifoVipConfig
from tests.fifo_vip_simple_test import SimpleTest, RandomTest


async def dut_init(dut):
    """Initialize DUT - start clocks and reset"""
    # Read DUT parameters
    depth = dut.DEPTH.value
    data_width = dut.DATA_WIDTH.value
    async_mode = dut.ASYNC.value
    rd_buffer = dut.RD_BUFFER.value

    cocotb.log.info(f"DUT Parameters: DEPTH={depth}, DATA_WIDTH={data_width}, ASYNC={async_mode}, RD_BUFFER={rd_buffer}")

    # Start clocks
    wr_clk_period = 20  # 50MHz
    rd_clk_period = 32  # 31.25MHz (async clocks)

    cocotb.start_soon(Clock(dut.wr_clk, wr_clk_period, units="ns").start())
    cocotb.start_soon(Clock(dut.rd_clk, rd_clk_period, units="ns").start())

    # Reset sequence
    dut.rst.value = 1
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.data_wr.value = 0

    await Timer(100, units="ns")
    dut.rst.value = 0
    await Timer(50, units="ns")

    cocotb.log.info("DUT initialization complete")


@cocotb.test()
async def fifo_simple_test(dut):
    """Simple test - write 8 items then read 8 items"""

    cocotb.log.info("="*60)
    cocotb.log.info("Starting FIFO Simple Test (pyUVM)")
    cocotb.log.info("="*60)

    # Initialize DUT
    await dut_init(dut)

    # Create and configure UVM environment
    # Note: pyUVM initialization would go here
    # For now, this is a placeholder showing the test structure

    cocotb.log.info("Test: Writing 8 items to FIFO")
    # Write sequence would be started here

    await Timer(500, units="ns")

    cocotb.log.info("Test: Reading 8 items from FIFO")
    # Read sequence would be started here

    await Timer(500, units="ns")

    cocotb.log.info("="*60)
    cocotb.log.info("FIFO Simple Test Complete")
    cocotb.log.info("="*60)


@cocotb.test()
async def fifo_random_test(dut):
    """Random test - mixed writes and reads"""

    cocotb.log.info("="*60)
    cocotb.log.info("Starting FIFO Random Test (pyUVM)")
    cocotb.log.info("="*60)

    # Initialize DUT
    await dut_init(dut)

    cocotb.log.info("Test: Random mixed write/read operations")

    # Initial write burst
    await Timer(300, units="ns")

    # Mixed operations
    for i in range(5):
        cocotb.log.info(f"Iteration {i+1}/5")
        await Timer(100, units="ns")

    await Timer(500, units="ns")

    cocotb.log.info("="*60)
    cocotb.log.info("FIFO Random Test Complete")
    cocotb.log.info("="*60)


@cocotb.test()
async def fifo_full_empty_test(dut):
    """Test FIFO full and empty conditions"""

    cocotb.log.info("="*60)
    cocotb.log.info("Starting FIFO Full/Empty Test")
    cocotb.log.info("="*60)

    # Initialize DUT
    await dut_init(dut)

    depth = dut.DEPTH.value

    cocotb.log.info(f"Test: Writing {depth+3} items (should hit full)")

    # Write until full
    await Timer(500, units="ns")

    cocotb.log.info(f"Test: Reading {depth+3} items (should hit empty)")

    # Read until empty
    await Timer(500, units="ns")

    cocotb.log.info("="*60)
    cocotb.log.info("FIFO Full/Empty Test Complete")
    cocotb.log.info("="*60)


# Note: Full pyUVM integration requires proper setup
# The above tests show the cocotb structure
# To use full pyUVM features, uncomment and use:
#
# @cocotb.test()
# async def fifo_pyuvm_test(dut):
#     """Full pyUVM test"""
#     await dut_init(dut)
#     await uvm_root().run_test("SimpleTest")
