"""
Singly Linked List VIP Base Test
Create Date: 01/05/2026

Base test class for Singly Linked List VIP
"""

from pyuvm import *
from cocotb.triggers import Timer
from ..env.sll_vip_env import SllVipEnv
from ..common.sll_vip_config import SllVipConfig


class BaseTest(uvm_test):
    """Base test for Singly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        """Build phase - create config and environment"""
        super().build_phase()

        # Create configuration
        self.cfg = SllVipConfig("sll_vip_cfg")

        # Get DUT parameters from cocotb
        dut = ConfigDB().get(None, "", "sll_vip_dut")
        if dut:
            try:
                self.cfg.DATA_WIDTH = int(dut.DATA_WIDTH.value)
                self.cfg.MAX_NODE = int(dut.MAX_NODE.value)
            except:
                self.logger.warning("Could not read DUT parameters, using defaults")

        # Set config
        ConfigDB().set(None, "*", "sll_vip_cfg", self.cfg)

        # Create environment
        self.env = SllVipEnv("env", self)

    def end_of_elaboration_phase(self):
        """Print topology"""
        super().end_of_elaboration_phase()
        self.logger.info("=" * 60)
        self.logger.info(f"Starting {self.get_name()} (pyUVM)")
        self.logger.info("=" * 60)
        self.logger.info(f"DUT Parameters: DATA_WIDTH={self.cfg.DATA_WIDTH}, MAX_NODE={self.cfg.MAX_NODE}")

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
