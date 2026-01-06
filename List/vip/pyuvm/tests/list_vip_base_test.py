"""
List VIP Base Test
Create Date: 01/05/2026

Base test class for List VIP
"""

from pyuvm import *
from ..env.list_vip_env import ListVipEnv
from ..common.list_vip_config import ListVipConfig


class BaseTest(uvm_test):
    """Base test for List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        """Build phase - create config and environment"""
        super().build_phase()

        # Create configuration
        self.cfg = ListVipConfig("list_vip_cfg")

        # Get DUT parameters from cocotb
        dut = ConfigDB().get(None, "", "list_vip_dut")
        if dut:
            try:
                self.cfg.DATA_WIDTH = int(dut.DATA_WIDTH.value)
                self.cfg.LENGTH = int(dut.LENGTH.value)
                self.cfg.SUM_METHOD = int(dut.SUM_METHOD.value)
            except:
                self.logger.warning("Could not read DUT parameters, using defaults")

        # Set config
        ConfigDB().set(None, "*", "list_vip_cfg", self.cfg)

        # Create environment
        self.env = ListVipEnv("env", self)

    def end_of_elaboration_phase(self):
        """Print topology"""
        super().end_of_elaboration_phase()
        self.logger.info("=" * 60)
        self.logger.info(f"Starting {self.get_name()} (pyUVM)")
        self.logger.info("=" * 60)
        self.logger.info(f"DUT Parameters: DATA_WIDTH={self.cfg.DATA_WIDTH}, "
                        f"LENGTH={self.cfg.LENGTH}, SUM_METHOD={self.cfg.SUM_METHOD}")

    async def run_phase(self):
        """Run phase - override in derived classes"""
        self.raise_objection()
        await Timer(100, units="ns")
        self.drop_objection()

    def report_phase(self):
        """Report phase"""
        super().report_phase()
        self.logger.info("=" * 60)
        self.logger.info(f"{self.get_name()} Complete")
        self.logger.info("=" * 60)
