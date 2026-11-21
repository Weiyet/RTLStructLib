import os
import cocotb
from cocotb.clock import Clock
from pyuvm import ConfigDB, uvm_root
from Bitmap_Free_List.vip.pyuvm.common.bitmap_vip_config import BitmapVipConfig
from Bitmap_Free_List.vip.pyuvm.tests.bitmap_vip_test import (
    BitmapVipBoundaryTest, BitmapVipRandomTest, BitmapVipResetTest, BitmapVipPassiveTest)


async def run(dut, test):
    for name in ("clk", "alloc_req", "free_req", "free_id"):
        getattr(dut, name).value = 0
    dut.rst.value = 1
    cfg = BitmapVipConfig.from_dut(dut, seed=int(os.getenv("TB_SEED", "123")),
                                  timeout_cycles=int(os.getenv("TB_TIMEOUT_CYCLES", "20000")))
    ConfigDB().set(None, "*", "bitmap_vip_cfg", cfg)
    clock = cocotb.start_soon(Clock(dut.clk, 10, units="ns").start(start_high=False))
    try:
        await uvm_root().run_test(test, keep_singletons=True)
    finally:
        clock.kill()


@cocotb.test()
async def bitmap_vip_boundary_test(dut):
    await run(dut, BitmapVipBoundaryTest)


@cocotb.test()
async def bitmap_vip_random_test(dut):
    await run(dut, BitmapVipRandomTest)


@cocotb.test()
async def bitmap_vip_reset_test(dut):
    await run(dut, BitmapVipResetTest)


@cocotb.test()
async def bitmap_vip_passive_test(dut):
    await run(dut, BitmapVipPassiveTest)
