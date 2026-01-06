"""Hash Table VIP Agent"""
from pyuvm import *
from .ht_vip_driver import HtVipDriver
from .ht_vip_monitor import HtVipMonitor
from .ht_vip_sequencer import HtVipSequencer

class HtVipAgent(uvm_agent):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.ap = None

    def build_phase(self):
        super().build_phase()
        self.monitor = HtVipMonitor("monitor", self)
        cfg = ConfigDB().get(self, "", "ht_vip_cfg")
        if cfg and cfg.is_active:
            self.driver = HtVipDriver("driver", self)
            self.sequencer = HtVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()
        self.ap = self.monitor.ap
        cfg = ConfigDB().get(self, "", "ht_vip_cfg")
        if cfg and cfg.is_active and self.driver and self.sequencer:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
