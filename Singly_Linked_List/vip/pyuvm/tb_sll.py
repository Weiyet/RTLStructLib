"""
Singly Linked List VIP Testbench
Create Date: 01/05/2026

Main testbench file for Singly Linked List pyUVM VIP
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from pyuvm import *

# Import test classes
from tests.sll_vip_simple_test import SimpleTest, RandomTest


async def dut_init(dut):
    """Initialize DUT"""
    # Get DUT parameters
    data_width = dut.DATA_WIDTH.value
    max_node = dut.MAX_NODE.value

    cocotb.log.info("=" * 60)
    cocotb.log.info("Singly Linked List VIP Testbench Initialization")
    cocotb.log.info("=" * 60)
    cocotb.log.info(f"DUT Parameters: DATA_WIDTH={data_width}, MAX_NODE={max_node}")

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.op.value = 0
    dut.op_start.value = 0
    dut.data_in.value = 0
    dut.addr_in.value = 0

    await Timer(100, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")

    # Store DUT in ConfigDB for VIP components
    ConfigDB().set(None, "*", "sll_vip_dut", dut)


@cocotb.test()
async def sll_simple_test(dut):
    """Simple test for Singly Linked List"""
    await dut_init(dut)

    cocotb.log.info("=" * 60)
    cocotb.log.info("Starting Singly Linked List Simple Test (pyUVM)")
    cocotb.log.info("=" * 60)

    # Run UVM test
    await uvm_root().run_test("SimpleTest")

    cocotb.log.info("=" * 60)
    cocotb.log.info("Singly Linked List Simple Test Complete")
    cocotb.log.info("=" * 60)


@cocotb.test()
async def sll_random_test(dut):
    """Random test for Singly Linked List"""
    await dut_init(dut)

    cocotb.log.info("=" * 60)
    cocotb.log.info("Starting Singly Linked List Random Test (pyUVM)")
    cocotb.log.info("=" * 60)

    # Run UVM test
    await uvm_root().run_test("RandomTest")

    cocotb.log.info("=" * 60)
    cocotb.log.info("Singly Linked List Random Test Complete")
    cocotb.log.info("=" * 60)
