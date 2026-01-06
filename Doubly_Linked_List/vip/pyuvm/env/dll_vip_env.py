"""
Doubly Linked List VIP Environment
Create Date: 01/05/2026

Environment containing agent and scoreboard
"""

from pyuvm import *
from ..agent.dll_vip_agent import DllVipAgent
from .dll_vip_scoreboard import DllVipScoreboard
from ..common.dll_vip_config import DllVipConfig


class DllVipEnv(uvm_env):
    """Environment for Doubly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.cfg = None
        self.agent = None
        self.sb = None

    def build_phase(self):
        super().build_phase()

        self.cfg = ConfigDB().get(self, "", "dll_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

        # Set config for all components
        ConfigDB().set(self, "*", "dll_vip_cfg", self.cfg)

        # Create agent
        if self.cfg.has_agent:
            self.agent = DllVipAgent("agent", self)

        # Create scoreboard
        if self.cfg.enable_scoreboard:
            self.sb = DllVipScoreboard("sb", self)

    def connect_phase(self):
        super().connect_phase()

        if self.cfg.enable_scoreboard and self.sb and self.agent:
            self.agent.ap.connect(self.sb.imp)

    def get_sequencer(self):
        """Helper function for tests"""
        if self.agent:
            return self.agent.sequencer
        return None
