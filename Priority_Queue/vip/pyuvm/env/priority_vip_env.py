from pyuvm import uvm_env
from ..agent.priority_vip_agent import PriorityVipAgent
from .priority_vip_scoreboard import PriorityVipScoreboard


class PriorityVipEnv(uvm_env):
    def build_phase(self):
        self.agent = PriorityVipAgent("agent", self)
        self.scoreboard = PriorityVipScoreboard("scoreboard", self)

    def connect_phase(self):
        self.agent.monitor.ap.connect(self.scoreboard.analysis_export)

    def get_sequencer(self):
        return self.agent.sequencer
