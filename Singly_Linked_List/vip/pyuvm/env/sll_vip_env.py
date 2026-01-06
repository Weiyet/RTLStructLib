"""
Singly Linked List VIP Environment
Create Date: 01/05/2026

Environment containing agent and scoreboard
"""

from pyuvm import *
from ..agent.sll_vip_agent import SllVipAgent
from .sll_vip_scoreboard import SllVipScoreboard
from ..common.sll_vip_config import SllVipConfig


class SllVipEnv(uvm_env):
    """Environment for Singly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.cfg = None
        self.agent = None
        self.sb = None

    def build_phase(self):
        super().build_phase()

        self.cfg = ConfigDB().get(self, "", "sll_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

        # Set config for all components
        ConfigDB().set(self, "*", "sll_vip_cfg", self.cfg)

        # Create agent
        if self.cfg.has_agent:
            self.agent = SllVipAgent("agent", self)

        # Create scoreboard
        if self.cfg.enable_scoreboard:
            self.sb = SllVipScoreboard("sb", self)

    def connect_phase(self):
        super().connect_phase()

        if self.cfg.enable_scoreboard and self.sb and self.agent:
            self.agent.ap.connect(self.sb.imp)

    def get_sequencer(self):
        """Helper function for tests"""
        if self.agent:
            return self.agent.sequencer
        return None
