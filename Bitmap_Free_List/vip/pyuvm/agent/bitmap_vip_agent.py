from pyuvm import ConfigDB, uvm_agent, uvm_sequencer
from .bitmap_vip_driver import BitmapVipDriver
from .bitmap_vip_monitor import BitmapVipMonitor


class BitmapVipAgent(uvm_agent):
    def build_phase(self):
        cfg = ConfigDB().get(self, "", "bitmap_vip_cfg")
        self.monitor = BitmapVipMonitor("monitor", self)
        self.driver = self.sequencer = None
        if cfg.active:
            self.driver = BitmapVipDriver("driver", self)
            self.sequencer = uvm_sequencer("sequencer", self)

    def connect_phase(self):
        if self.driver is not None:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
