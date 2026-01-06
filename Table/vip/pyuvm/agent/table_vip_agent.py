"""Table VIP Agent"""
from pyuvm import uvm_agent
from .table_vip_driver import TableVipDriver
from .table_vip_monitor import TableVipMonitor
from .table_vip_sequencer import TableVipSequencer

class TableVipAgent(uvm_agent):
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
        if not ConfigDB().get(self, "", "table_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

        # Always create monitor
        self.monitor = TableVipMonitor("monitor", self)

        # Create driver and sequencer (always active for table)
        self.driver = TableVipDriver("driver", self)
        self.sequencer = TableVipSequencer("sequencer", self)

    def connect_phase(self):
        super().connect_phase()
        self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
