"""LIFO VIP Testbench"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge
from pyuvm import *
from tests.lifo_vip_simple_test import SimpleTest

async def dut_init(dut):
    """Initialize DUT"""
    cocotb.log.info("="*60)
    cocotb.log.info("LIFO VIP Testbench Initialization")
    cocotb.log.info("="*60)

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.data_wr.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0

    await Timer(50, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")
    ConfigDB().set(None, "*", "lifo_vip_dut", dut)

@cocotb.test()
async def lifo_simple_test(dut):
    """Simple test for LIFO"""
    await dut_init(dut)
    cocotb.log.info("Starting LIFO Simple Test (pyUVM)")
    await uvm_root().run_test("SimpleTest")
    cocotb.log.info("LIFO Simple Test Complete")
