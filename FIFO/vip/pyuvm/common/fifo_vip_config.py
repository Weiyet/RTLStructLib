"""
FIFO VIP Configuration Class
Create Date: 01/05/2026
"""

from pyuvm import *
from .fifo_vip_types import FifoAgentMode


class FifoVipConfig(uvm_object):
    """Configuration object for FIFO VIP"""

    def __init__(self, name="fifo_vip_config"):
        super().__init__(name)
        # DUT parameters - CHANGE THESE FOR YOUR FIFO
        self.DEPTH = 12
        self.DATA_WIDTH = 8
        self.ASYNC = 1  # 1=async clocks, 0=sync
        self.RD_BUFFER = 1  # 1=buffered read, 0=combinational

        # VIP control
        self.has_wr_agent = True
        self.has_rd_agent = True
        self.enable_scoreboard = True

        # Agent modes
        self.wr_agent_mode = FifoAgentMode.MASTER
        self.rd_agent_mode = FifoAgentMode.MASTER

    def print_config(self):
        """Print configuration"""
        self.logger.info(
            f"DEPTH={self.DEPTH}, DATA_WIDTH={self.DATA_WIDTH}, "
            f"ASYNC={self.ASYNC}, RD_BUFFER={self.RD_BUFFER}"
        )

    def __str__(self):
        return (f"FifoVipConfig: DEPTH={self.DEPTH}, DATA_WIDTH={self.DATA_WIDTH}, "
                f"ASYNC={self.ASYNC}, RD_BUFFER={self.RD_BUFFER}")
