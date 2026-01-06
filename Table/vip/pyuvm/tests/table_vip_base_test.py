"""Table VIP Base Test"""
from pyuvm import *
from ..env.table_vip_env import TableVipEnv
from ..common.table_vip_config import TableVipConfig

class BaseTest(uvm_test):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()

        # Create configuration
        self.cfg = TableVipConfig("cfg")
        self.cfg.TABLE_SIZE = 32
        self.cfg.DATA_WIDTH = 8
        self.cfg.INPUT_RATE = 2
        self.cfg.OUTPUT_RATE = 2

        # Set config in ConfigDB
        ConfigDB().set(None, "*", "table_vip_cfg", self.cfg)

        # Get DUT from ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "table_vip_dut", arr):
            self.logger.critical("No DUT found in ConfigDB!")

        # Create environment
        self.env = TableVipEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        # Base test does nothing - override in derived classes
        self.drop_objection()
