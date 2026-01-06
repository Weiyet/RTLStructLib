"""LIFO VIP Environment"""
from pyuvm import uvm_env, ConfigDB
from ..agent.lifo_vip_agent import LifoVipAgent
from .lifo_vip_scoreboard import LifoVipScoreboard

class LifoVipEnv(uvm_env):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.agent = None
        self.scoreboard = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

        # Create agent
        if self.cfg.has_agent:
            self.agent = LifoVipAgent("agent", self)

        # Create scoreboard
        if self.cfg.enable_scoreboard:
            self.scoreboard = LifoVipScoreboard("scoreboard", self)

    def connect_phase(self):
        super().connect_phase()
        if self.cfg.has_agent and self.cfg.enable_scoreboard:
            self.agent.monitor.ap.connect(self.scoreboard.imp)

    def get_sequencer(self):
        """Return sequencer for use by sequences"""
        if self.agent and self.agent.sequencer:
            return self.agent.sequencer
        return None
