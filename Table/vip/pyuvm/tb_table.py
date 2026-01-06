"""Table VIP Testbench"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge
from pyuvm import *
from tests.table_vip_simple_test import SimpleTest

async def dut_init(dut):
    """Initialize DUT"""
    cocotb.log.info("="*60)
    cocotb.log.info("Table VIP Testbench Initialization")
    cocotb.log.info("="*60)

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.index_wr.value = 0
    dut.index_rd.value = 0
    dut.data_wr.value = 0

    await Timer(50, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    cocotb.log.info("DUT initialization complete")
    ConfigDB().set(None, "*", "table_vip_dut", dut)

@cocotb.test()
async def table_simple_test(dut):
    """Simple test for Table"""
    await dut_init(dut)
    cocotb.log.info("Starting Table Simple Test (pyUVM)")
    await uvm_root().run_test("SimpleTest")
    cocotb.log.info("Table Simple Test Complete")
