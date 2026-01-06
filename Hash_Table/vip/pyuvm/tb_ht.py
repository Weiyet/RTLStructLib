"""Hash Table VIP Testbench"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from pyuvm import *
from tests.ht_vip_simple_test import SimpleTest, RandomTest

async def dut_init(dut):
    """Initialize DUT"""
    cocotb.log.info("="*60)
    cocotb.log.info("Hash Table VIP Testbench Initialization")
    cocotb.log.info("="*60)

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.op_sel.value = 3
    dut.op_en.value = 0
    dut.key_in.value = 0
    dut.value_in.value = 0

    await Timer(100, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")
    ConfigDB().set(None, "*", "ht_vip_dut", dut)

@cocotb.test()
async def ht_simple_test(dut):
    """Simple test for Hash Table"""
    await dut_init(dut)
    cocotb.log.info("Starting Hash Table Simple Test (pyUVM)")
    await uvm_root().run_test("SimpleTest")
    cocotb.log.info("Hash Table Simple Test Complete")

@cocotb.test()
async def ht_random_test(dut):
    """Random test for Hash Table"""
    await dut_init(dut)
    cocotb.log.info("Starting Hash Table Random Test (pyUVM)")
    await uvm_root().run_test("RandomTest")
    cocotb.log.info("Hash Table Random Test Complete")
