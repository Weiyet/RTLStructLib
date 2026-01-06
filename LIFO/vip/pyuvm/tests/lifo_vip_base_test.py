"""LIFO VIP Base Test"""
from pyuvm import *
from ..env.lifo_vip_env import LifoVipEnv
from ..common.lifo_vip_config import LifoVipConfig

class BaseTest(uvm_test):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()

        # Create configuration
        self.cfg = LifoVipConfig("cfg")
        self.cfg.DEPTH = 12
        self.cfg.DATA_WIDTH = 8
        self.cfg.has_agent = True
        self.cfg.enable_scoreboard = True
        self.cfg.is_active = True

        # Set config in ConfigDB
        ConfigDB().set(None, "*", "lifo_vip_cfg", self.cfg)

        # Get DUT from ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_dut", arr):
            self.logger.critical("No DUT found in ConfigDB!")

        # Create environment
        self.env = LifoVipEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        # Base test does nothing - override in derived classes
        self.drop_objection()
