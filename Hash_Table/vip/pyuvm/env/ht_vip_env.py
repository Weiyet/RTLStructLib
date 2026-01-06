"""Hash Table VIP Environment"""
from pyuvm import *
from ..agent.ht_vip_agent import HtVipAgent
from .ht_vip_scoreboard import HtVipScoreboard

class HtVipEnv(uvm_env):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.cfg = None
        self.agent = None
        self.sb = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "ht_vip_cfg")
        ConfigDB().set(self, "*", "ht_vip_cfg", self.cfg)
        if self.cfg.has_agent:
            self.agent = HtVipAgent("agent", self)
        if self.cfg.enable_scoreboard:
            self.sb = HtVipScoreboard("sb", self)

    def connect_phase(self):
        super().connect_phase()
        if self.cfg.enable_scoreboard and self.sb and self.agent:
            self.agent.ap.connect(self.sb.imp)

    def get_sequencer(self):
        return self.agent.sequencer if self.agent else None
