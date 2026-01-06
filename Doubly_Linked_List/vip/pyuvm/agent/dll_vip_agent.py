"""
Doubly Linked List VIP Agent
Create Date: 01/05/2026

Agent wrapper containing driver, monitor, and sequencer
"""

from pyuvm import *
from .dll_vip_driver import DllVipDriver
from .dll_vip_monitor import DllVipMonitor
from .dll_vip_sequencer import DllVipSequencer


class DllVipAgent(uvm_agent):
    """Agent for Doubly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.ap = None

    def build_phase(self):
        super().build_phase()

        # Always create monitor
        self.monitor = DllVipMonitor("monitor", self)

        # Create driver and sequencer if active
        cfg = ConfigDB().get(self, "", "dll_vip_cfg")
        if cfg and cfg.is_active:
            self.driver = DllVipDriver("driver", self)
            self.sequencer = DllVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()

        # Connect analysis port
        self.ap = self.monitor.ap

        # Connect driver to sequencer if active
        cfg = ConfigDB().get(self, "", "dll_vip_cfg")
        if cfg and cfg.is_active and self.driver and self.sequencer:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
