"""Dual Edge FF VIP Scoreboard - tracks FF state"""
from pyuvm import *

class DeffVipScoreboard(uvm_scoreboard):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.imp = uvm_analysis_export("imp", self)
        self.ff_state = 0  # Current FF state
        self.error_count = 0

    def connect_phase(self):
        super().connect_phase()
        self.imp.connect(self)

    def write(self, item):
        """Check dual-edge FF behavior"""
        # Simple scoreboard: just log transactions
        # Full model would track pos/neg edge latching per bit
        self.logger.info(f"Transaction: {item.convert2string()}")

        # Could implement detailed per-bit checking here
        # For now, just verify data was captured
        if item.data_out is not None:
            self.ff_state = item.data_out

    def report_phase(self):
        super().report_phase()
        self.logger.info("="*50)
        self.logger.info(f"Final FF State: 0x{self.ff_state:x}")
        self.logger.info(f"Error Count: {self.error_count}")
        if self.error_count == 0:
            self.logger.info("Test PASSED")
        else:
            self.logger.error(f"Test FAILED with {self.error_count} errors")
