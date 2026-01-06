"""Dual Edge FF VIP Agent"""
from pyuvm import *
from .deff_vip_driver import DeffVipDriver
from .deff_vip_monitor import DeffVipMonitor
from .deff_vip_sequencer import DeffVipSequencer

class DeffVipAgent(uvm_agent):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.ap = None

    def build_phase(self):
        super().build_phase()
        self.monitor = DeffVipMonitor("monitor", self)
        cfg = ConfigDB().get(self, "", "deff_vip_cfg")
        if cfg and cfg.is_active:
            self.driver = DeffVipDriver("driver", self)
            self.sequencer = DeffVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()
        self.ap = self.monitor.ap
        cfg = ConfigDB().get(self, "", "deff_vip_cfg")
        if cfg and cfg.is_active and self.driver and self.sequencer:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
