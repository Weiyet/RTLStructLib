"""LIFO VIP Scoreboard"""
from pyuvm import uvm_scoreboard, uvm_analysis_imp
from ..common import LifoOp

class LifoVipScoreboard(uvm_scoreboard):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.imp = uvm_analysis_imp("imp", self)
        self.cfg = None
        self.expected_queue = []  # Python list as LIFO model
        self.push_count = 0
        self.pop_count = 0
        self.error_count = 0
        self.bypass_count = 0

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

    def write(self, item):
        """Receive transaction from monitor"""
        if item.op == LifoOp.PUSH:
            self.check_push(item)
        elif item.op == LifoOp.POP:
            self.check_pop(item)

    def check_push(self, item):
        """Check PUSH operation"""
        if item.success:
            # Successful push - add to model
            self.expected_queue.append(item.data)
            self.push_count += 1
            self.logger.info(f"PUSH: data=0x{item.data:x} depth={len(self.expected_queue)}")

            # Check full flag
            if len(self.expected_queue) == self.cfg.DEPTH and not item.full:
                self.logger.error(f"LIFO should be full but full flag not set. Depth={len(self.expected_queue)}")
                self.error_count += 1
        else:
            # Failed push due to full LIFO
            if not item.full:
                self.logger.error("Push failed but full flag not set")
                self.error_count += 1
            self.logger.info("PUSH failed - LIFO full")

    def check_pop(self, item):
        """Check POP operation"""
        if item.success:
            # Successful pop - check data
            if len(self.expected_queue) == 0:
                self.logger.error("Pop succeeded but model is empty")
                self.error_count += 1
                return

            expected_data = self.expected_queue.pop()  # LIFO: pop from back
            self.pop_count += 1

            if item.read_data != expected_data:
                self.logger.error(f"Data mismatch! Expected=0x{expected_data:x} Actual=0x{item.read_data:x}")
                self.error_count += 1
            else:
                self.logger.info(f"POP: data=0x{item.read_data:x} depth={len(self.expected_queue)} MATCH")

            # Check empty flag
            if len(self.expected_queue) == 0 and not item.empty:
                self.logger.error("LIFO should be empty but empty flag not set")
                self.error_count += 1
        else:
            # Failed pop due to empty LIFO
            if not item.empty:
                self.logger.error("Pop failed but empty flag not set")
                self.error_count += 1
            self.logger.info("POP failed - LIFO empty")

    def report_phase(self):
        super().report_phase()
        self.logger.info("=" * 50)
        self.logger.info(f"Push Count: {self.push_count}")
        self.logger.info(f"Pop Count: {self.pop_count}")
        self.logger.info(f"Error Count: {self.error_count}")
        self.logger.info(f"Final Queue Depth: {len(self.expected_queue)}")
        self.logger.info("=" * 50)

        if self.error_count > 0:
            self.logger.error(f"Test FAILED with {self.error_count} errors")
        else:
            self.logger.info("Test PASSED - No errors detected")
