"""
FIFO VIP Environment
Create Date: 01/05/2026
"""

from pyuvm import *
from ..agent.fifo_vip_agent import FifoVipAgent
from .fifo_vip_scoreboard import FifoVipScoreboard


class FifoVipEnv(uvm_env):
    """Environment for FIFO VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.cfg = None
        self.wr_agent = None
        self.rd_agent = None
        self.sb = None

    def build_phase(self):
        super().build_phase()

        # Get config
        self.cfg = ConfigDB().get(self, "", "fifo_vip_cfg")
        if self.cfg is None:
            self.logger.critical("No config found")

        # Set config for all components
        ConfigDB().set(self, "*", "fifo_vip_cfg", self.cfg)

        # Create agents
        if self.cfg.has_wr_agent:
            self.wr_agent = FifoVipAgent("wr_agent", self, agent_type="WR")

        if self.cfg.has_rd_agent:
            self.rd_agent = FifoVipAgent("rd_agent", self, agent_type="RD")

        # Create scoreboard
        if self.cfg.enable_scoreboard:
            self.sb = FifoVipScoreboard("sb", self)

    def connect_phase(self):
        super().connect_phase()

        # Connect agents to scoreboard
        if self.cfg.enable_scoreboard and self.sb is not None:
            if self.wr_agent is not None:
                self.wr_agent.ap.connect(self.sb.wr_export)
                # Connect write callback
                self.sb.wr_export.connect_transaction_handler(self.sb.write_wr)

            if self.rd_agent is not None:
                self.rd_agent.ap.connect(self.sb.rd_export)
                # Connect read callback
                self.sb.rd_export.connect_transaction_handler(self.sb.write_rd)

    def get_wr_sequencer(self):
        """Get write sequencer"""
        if self.wr_agent is not None:
            return self.wr_agent.sequencer
        return None

    def get_rd_sequencer(self):
        """Get read sequencer"""
        if self.rd_agent is not None:
            return self.rd_agent.sequencer
        return None
