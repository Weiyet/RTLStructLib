"""Dual Edge FF VIP Environment"""
from pyuvm import *
from ..agent.deff_vip_agent import DeffVipAgent
from .deff_vip_scoreboard import DeffVipScoreboard

class DeffVipEnv(uvm_env):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.cfg = None
        self.agent = None
        self.sb = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "deff_vip_cfg")
        ConfigDB().set(self, "*", "deff_vip_cfg", self.cfg)
        if self.cfg.has_agent:
            self.agent = DeffVipAgent("agent", self)
        if self.cfg.enable_scoreboard:
            self.sb = DeffVipScoreboard("sb", self)

    def connect_phase(self):
        super().connect_phase()
        if self.cfg.enable_scoreboard and self.sb and self.agent:
            self.agent.ap.connect(self.sb.imp)

    def get_sequencer(self):
        return self.agent.sequencer if self.agent else None
