"""LIFO VIP Agent"""
from pyuvm import uvm_agent
from .lifo_vip_driver import LifoVipDriver
from .lifo_vip_monitor import LifoVipMonitor
from .lifo_vip_sequencer import LifoVipSequencer

class LifoVipAgent(uvm_agent):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

        # Always create monitor
        self.monitor = LifoVipMonitor("monitor", self)

        # Create driver and sequencer if active
        if self.cfg.is_active:
            self.driver = LifoVipDriver("driver", self)
            self.sequencer = LifoVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()
        if self.cfg.is_active:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
