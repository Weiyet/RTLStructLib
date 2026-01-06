"""Hash Table VIP Scoreboard - tracks key-value pairs"""
from pyuvm import *
from ..common.ht_vip_types import HtOp

class HtVipScoreboard(uvm_scoreboard):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.imp = uvm_analysis_export("imp", self)
        self.hash_model = {}  # Python dict as reference model
        self.error_count = 0

    def connect_phase(self):
        super().connect_phase()
        self.imp.connect(self)

    def write(self, item):
        if item.op == HtOp.INSERT:
            if not item.op_error:
                self.hash_model[item.key] = item.value
                self.logger.info(f"INSERT key=0x{item.key:x} value=0x{item.value:x}")
        elif item.op == HtOp.DELETE:
            if not item.op_error:
                if item.key in self.hash_model:
                    del self.hash_model[item.key]
                    self.logger.info(f"DELETE key=0x{item.key:x}")
        elif item.op == HtOp.SEARCH:
            if item.key in self.hash_model:
                if item.result_value != self.hash_model[item.key]:
                    self.logger.error(f"SEARCH mismatch! Expected=0x{self.hash_model[item.key]:x} Actual=0x{item.result_value:x}")
                    self.error_count += 1
                else:
                    self.logger.info(f"SEARCH key=0x{item.key:x} MATCH")

    def report_phase(self):
        super().report_phase()
        self.logger.info("="*50)
        self.logger.info(f"Hash Table Size: {len(self.hash_model)}")
        self.logger.info(f"Error Count: {self.error_count}")
        if self.error_count > 0:
            self.logger.error(f"Test FAILED with {self.error_count} errors")
        else:
            self.logger.info("Test PASSED")
