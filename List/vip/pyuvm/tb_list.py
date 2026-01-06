"""
List VIP Testbench
Create Date: 01/05/2026

Main testbench file for List pyUVM VIP
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from pyuvm import *

# Import test classes
from tests.list_vip_simple_test import SimpleTest, RandomTest


async def dut_init(dut):
    """Initialize DUT"""
    # Get DUT parameters
    depth = dut.LENGTH.value
    data_width = dut.DATA_WIDTH.value
    sum_method = dut.SUM_METHOD.value

    cocotb.log.info("=" * 60)
    cocotb.log.info("List VIP Testbench Initialization")
    cocotb.log.info("=" * 60)
    cocotb.log.info(f"DUT Parameters: LENGTH={depth}, DATA_WIDTH={data_width}, SUM_METHOD={sum_method}")

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.op_sel.value = 0
    dut.op_en.value = 0
    dut.data_in.value = 0
    dut.index_in.value = 0

    await Timer(100, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")

    # Store DUT in ConfigDB for VIP components
    ConfigDB().set(None, "*", "list_vip_dut", dut)


@cocotb.test()
async def list_simple_test(dut):
    """Simple test for List"""
    await dut_init(dut)

    cocotb.log.info("=" * 60)
    cocotb.log.info("Starting List Simple Test (pyUVM)")
    cocotb.log.info("=" * 60)

    # Run UVM test
    await uvm_root().run_test("SimpleTest")

    cocotb.log.info("=" * 60)
    cocotb.log.info("List Simple Test Complete")
    cocotb.log.info("=" * 60)


@cocotb.test()
async def list_random_test(dut):
    """Random test for List"""
    await dut_init(dut)

    cocotb.log.info("=" * 60)
    cocotb.log.info("Starting List Random Test (pyUVM)")
    cocotb.log.info("=" * 60)

    # Run UVM test
    await uvm_root().run_test("RandomTest")

    cocotb.log.info("=" * 60)
    cocotb.log.info("List Random Test Complete")
    cocotb.log.info("=" * 60)
