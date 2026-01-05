"""
FIFO VIP Base Test
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import Timer
from ..common.fifo_vip_config import FifoVipConfig
from ..env.fifo_vip_env import FifoVipEnv


class BaseTest(uvm_test):
    """Base test for FIFO VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.env = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()

        # Create config
        self.cfg = FifoVipConfig("cfg")
        self.cfg.DEPTH = 12
        self.cfg.DATA_WIDTH = 8
        self.cfg.ASYNC = 1
        self.cfg.RD_BUFFER = 1
        self.cfg.has_wr_agent = True
        self.cfg.has_rd_agent = True
        self.cfg.enable_scoreboard = True

        # Set config in database
        ConfigDB().set(None, "*", "fifo_vip_cfg", self.cfg)

        # Create environment
        self.env = FifoVipEnv("env", self)

    def end_of_elaboration_phase(self):
        super().end_of_elaboration_phase()
        self.logger.info("Test build complete")
        if self.cfg:
            self.cfg.print_config()
