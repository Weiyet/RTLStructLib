"""
FIFO VIP Agent
Create Date: 01/05/2026
"""

from pyuvm import *
from .fifo_vip_driver import FifoVipDriver
from .fifo_vip_monitor import FifoVipMonitor
from .fifo_vip_sequencer import FifoVipSequencer


class FifoVipAgent(uvm_agent):
    """Agent for FIFO VIP"""

    def __init__(self, name, parent, agent_type="WR"):
        super().__init__(name, parent)
        self.agent_type = agent_type  # "WR" or "RD"
        self.driver = None
        self.monitor = None
        self.sequencer = None
        self.ap = None

    def build_phase(self):
        super().build_phase()

        # Create monitor
        self.monitor = FifoVipMonitor(
            f"{self.agent_type.lower()}_monitor",
            self,
            monitor_type=self.agent_type
        )

        # Create driver and sequencer if active
        if self.is_active == UVM_ACTIVE:
            self.driver = FifoVipDriver(
                f"{self.agent_type.lower()}_driver",
                self,
                driver_type=self.agent_type
            )
            self.sequencer = FifoVipSequencer(
                f"{self.agent_type.lower()}_sequencer",
                self
            )

    def connect_phase(self):
        super().connect_phase()

        # Connect analysis port
        self.ap = self.monitor.ap

        # Connect driver to sequencer if active
        if self.is_active == UVM_ACTIVE:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
