from pyuvm import uvm_env
from ..agent.bitmap_vip_agent import BitmapVipAgent
from .bitmap_vip_scoreboard import BitmapVipScoreboard


class BitmapVipEnv(uvm_env):
    def build_phase(self):
        self.agent = BitmapVipAgent("agent", self)
        self.scoreboard = BitmapVipScoreboard("scoreboard", self)

    def connect_phase(self):
        self.agent.monitor.ap.connect(self.scoreboard.analysis_export)

    def get_sequencer(self):
        return self.agent.sequencer
