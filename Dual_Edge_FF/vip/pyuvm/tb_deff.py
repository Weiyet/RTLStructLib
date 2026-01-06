"""Dual Edge FF VIP Testbench"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge
from pyuvm import *
from tests.deff_vip_simple_test import SimpleTest

async def dut_init(dut):
    """Initialize DUT"""
    cocotb.log.info("="*60)
    cocotb.log.info("Dual Edge FF VIP Testbench Initialization")
    cocotb.log.info("="*60)

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset (active low)
    dut.rst_n.value = 0
    dut.data_in.value = 0
    dut.pos_edge_latch_en.value = 0
    dut.neg_edge_latch_en.value = 0

    await Timer(50, units="ns")
    dut.rst_n.value = 1
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")
    ConfigDB().set(None, "*", "deff_vip_dut", dut)

@cocotb.test()
async def deff_simple_test(dut):
    """Simple test for Dual Edge FF"""
    await dut_init(dut)
    cocotb.log.info("Starting Dual Edge FF Simple Test (pyUVM)")
    await uvm_root().run_test("SimpleTest")
    cocotb.log.info("Dual Edge FF Simple Test Complete")
