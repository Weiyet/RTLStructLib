"""Dual Edge FF VIP Base Test"""
from pyuvm import *
from cocotb.triggers import Timer
from ..env.deff_vip_env import DeffVipEnv
from ..common.deff_vip_config import DeffVipConfig

class BaseTest(uvm_test):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = DeffVipConfig("deff_vip_cfg")

        dut = ConfigDB().get(None, "", "deff_vip_dut")
        if dut:
            try:
                self.cfg.DATA_WIDTH = int(dut.DATA_WIDTH.value)
                self.cfg.RESET_VALUE = int(dut.RESET_VALUE.value)
            except:
                self.logger.warning("Could not read DUT parameters")

        ConfigDB().set(None, "*", "deff_vip_cfg", self.cfg)
        self.env = DeffVipEnv("env", self)

    def end_of_elaboration_phase(self):
        super().end_of_elaboration_phase()
        self.logger.info("="*60)
        self.logger.info(f"Starting {self.get_name()} (pyUVM)")
        self.logger.info("="*60)

    async def run_phase(self):
        self.raise_objection()
        await Timer(100, units="ns")
        self.drop_objection()

    def report_phase(self):
        super().report_phase()
        self.logger.info("="*60)
        self.logger.info(f"{self.get_name()} Complete")
        self.logger.info("="*60)
