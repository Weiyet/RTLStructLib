from pyuvm import ConfigDB, uvm_agent
from .priority_vip_driver import PriorityVipDriver
from .priority_vip_monitor import PriorityVipMonitor
from .priority_vip_sequencer import PriorityVipSequencer


class PriorityVipAgent(uvm_agent):
    def build_phase(self):
        cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.monitor = PriorityVipMonitor("monitor", self)
        self.sequencer = self.driver = None
        if cfg.active:
            self.sequencer = PriorityVipSequencer("sequencer", self)
            self.driver = PriorityVipDriver("driver", self)

    def connect_phase(self):
        if self.driver is not None:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
