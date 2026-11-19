import os
import cocotb
from cocotb.clock import Clock
from pyuvm import ConfigDB, uvm_root
from Priority_Queue.vip.pyuvm.common.priority_vip_config import PriorityVipConfig
from Priority_Queue.vip.pyuvm.tests.priority_vip_boundary_test import PriorityVipBoundaryTest
from Priority_Queue.vip.pyuvm.tests.priority_vip_random_test import PriorityVipRandomTest
from Priority_Queue.vip.pyuvm.tests.priority_vip_reset_test import PriorityVipResetTest
from Priority_Queue.vip.pyuvm.tests.priority_vip_passive_test import PriorityVipPassiveTest


async def run(dut, test):
    for name in ("clk", "req_valid", "req_op", "req_priority", "req_data", "rsp_ready"):
        getattr(dut, name).value = 0
    dut.rst.value = 1
    cfg = PriorityVipConfig.from_dut(dut, seed=int(os.getenv("TB_SEED", "123")),
                                   timeout_cycles=int(os.getenv("TB_TIMEOUT_CYCLES", "100000")))
    # ConfigDB is cleared by run_test unless explicitly retained.
    ConfigDB().set(None, "*", "priority_vip_cfg", cfg)
    clock = cocotb.start_soon(Clock(dut.clk, 10, units="ns").start(start_high=False))
    try:
        await uvm_root().run_test(test, keep_singletons=True)
    finally:
        clock.kill()


@cocotb.test()
async def priority_vip_boundary_test(dut):
    await run(dut, PriorityVipBoundaryTest)


@cocotb.test()
async def priority_vip_random_test(dut):
    await run(dut, PriorityVipRandomTest)


@cocotb.test()
async def priority_vip_reset_test(dut):
    await run(dut, PriorityVipResetTest)


@cocotb.test()
async def priority_vip_passive_test(dut):
    await run(dut, PriorityVipPassiveTest)
