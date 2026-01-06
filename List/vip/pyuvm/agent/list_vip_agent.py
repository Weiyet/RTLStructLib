"""
List VIP Agent
Create Date: 01/05/2026

Agent wrapper containing driver, monitor, and sequencer
"""

from pyuvm import *
from .list_vip_driver import ListVipDriver
from .list_vip_monitor import ListVipMonitor
from .list_vip_sequencer import ListVipSequencer


class ListVipAgent(uvm_agent):
    """Agent for List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.ap = None

    def build_phase(self):
        super().build_phase()

        # Always create monitor
        self.monitor = ListVipMonitor("monitor", self)

        # Create driver and sequencer if active
        cfg = ConfigDB().get(self, "", "list_vip_cfg")
        if cfg and cfg.is_active:
            self.driver = ListVipDriver("driver", self)
            self.sequencer = ListVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()

        # Connect analysis port
        self.ap = self.monitor.ap

        # Connect driver to sequencer if active
        cfg = ConfigDB().get(self, "", "list_vip_cfg")
        if cfg and cfg.is_active and self.driver and self.sequencer:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
