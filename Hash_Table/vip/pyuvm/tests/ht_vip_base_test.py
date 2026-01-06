"""Hash Table VIP Base Test"""
from pyuvm import *
from cocotb.triggers import Timer
from ..env.ht_vip_env import HtVipEnv
from ..common.ht_vip_config import HtVipConfig

class BaseTest(uvm_test):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = HtVipConfig("ht_vip_cfg")

        dut = ConfigDB().get(None, "", "ht_vip_dut")
        if dut:
            try:
                self.cfg.KEY_WIDTH = int(dut.KEY_WIDTH.value)
                self.cfg.VALUE_WIDTH = int(dut.VALUE_WIDTH.value)
                self.cfg.TOTAL_INDEX = int(dut.TOTAL_INDEX.value)
                self.cfg.CHAINING_SIZE = int(dut.CHAINING_SIZE.value)
            except:
                self.logger.warning("Could not read DUT parameters, using defaults")

        ConfigDB().set(None, "*", "ht_vip_cfg", self.cfg)
        self.env = HtVipEnv("env", self)

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
