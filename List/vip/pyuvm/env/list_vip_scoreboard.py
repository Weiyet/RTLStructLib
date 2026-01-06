"""
List VIP Scoreboard
Create Date: 01/05/2026

Scoreboard for List VIP - self-checking component with list model
"""

from pyuvm import *
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp
from ..common.list_vip_config import ListVipConfig


class ListVipScoreboard(uvm_scoreboard):
    """Scoreboard for List VIP with reference model"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.imp = uvm_analysis_export("imp", self)
        self.cfg = None
        self.list_model = []  # Python list as reference model
        self.error_count = 0
        self.insert_count = 0
        self.delete_count = 0
        self.read_count = 0
        self.search_count = 0
        self.sort_count = 0
        self.sum_count = 0

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "list_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    def connect_phase(self):
        super().connect_phase()
        self.imp.connect(self)

    def write(self, item):
        """Analysis write method - called by monitor"""
        if item.op == ListOp.READ:
            self.check_read(item)
        elif item.op == ListOp.INSERT:
            self.check_insert(item)
        elif item.op == ListOp.DELETE:
            self.check_delete(item)
        elif item.op == ListOp.FIND_1ST:
            self.check_find_1st(item)
        elif item.op == ListOp.FIND_ALL:
            self.check_find_all(item)
        elif item.op == ListOp.SUM:
            self.check_sum(item)
        elif item.op == ListOp.SORT_ASC:
            self.check_sort_asc(item)
        elif item.op == ListOp.SORT_DES:
            self.check_sort_des(item)

        # Check length
        if item.current_len != len(self.list_model):
            self.logger.error(f"Length mismatch! Expected={len(self.list_model)} Actual={item.current_len}")
            self.error_count += 1

    def check_read(self, item):
        """Check READ operation"""
        self.read_count += 1

        if item.index >= len(self.list_model):
            # Out of bounds read
            if not item.op_error:
                self.logger.error(f"READ[{item.index}]: Should error (out of bounds) but didn't")
                self.error_count += 1
        else:
            # Valid read
            if item.op_error:
                self.logger.error(f"READ[{item.index}]: Should not error")
                self.error_count += 1
            if item.result_data != self.list_model[item.index]:
                self.logger.error(f"READ[{item.index}]: Data mismatch! Expected=0x{self.list_model[item.index]:x} Actual=0x{item.result_data:x}")
                self.error_count += 1
            else:
                self.logger.info(f"READ[{item.index}]: data=0x{item.result_data:x} MATCH")

    def check_insert(self, item):
        """Check INSERT operation"""
        self.insert_count += 1

        if len(self.list_model) >= self.cfg.LENGTH:
            # List full
            if not item.op_error:
                self.logger.error("INSERT: Should error (list full) but didn't")
                self.error_count += 1
        else:
            # Valid insert
            if item.op_error:
                self.logger.error("INSERT: Should not error")
                self.error_count += 1

            if item.index >= len(self.list_model):
                # Append at end
                self.list_model.append(item.data)
            else:
                # Insert at index
                self.list_model.insert(item.index, item.data)
            self.logger.info(f"INSERT[{item.index}]: data=0x{item.data:x} len={len(self.list_model)}")

    def check_delete(self, item):
        """Check DELETE operation"""
        self.delete_count += 1

        if item.index >= len(self.list_model):
            # Out of bounds delete
            if not item.op_error:
                self.logger.error(f"DELETE[{item.index}]: Should error (out of bounds) but didn't")
                self.error_count += 1
        else:
            # Valid delete
            if item.op_error:
                self.logger.error(f"DELETE[{item.index}]: Should not error")
                self.error_count += 1
            del self.list_model[item.index]
            self.logger.info(f"DELETE[{item.index}]: len={len(self.list_model)}")

    def check_find_1st(self, item):
        """Check FIND_1ST operation"""
        self.search_count += 1

        # Search for first occurrence
        found_idx = -1
        for i, val in enumerate(self.list_model):
            if val == item.data:
                found_idx = i
                break

        if found_idx == -1:
            # Not found
            if not item.op_error:
                self.logger.error(f"FIND_1ST(0x{item.data:x}): Should error (not found) but didn't")
                self.error_count += 1
        else:
            # Found
            if item.op_error:
                self.logger.error(f"FIND_1ST(0x{item.data:x}): Should not error")
                self.error_count += 1
            if item.result_data != found_idx:
                self.logger.error(f"FIND_1ST(0x{item.data:x}): Index mismatch! Expected={found_idx} Actual={item.result_data}")
                self.error_count += 1
            else:
                self.logger.info(f"FIND_1ST(0x{item.data:x}): index={found_idx} MATCH")

    def check_find_all(self, item):
        """Check FIND_ALL operation (simplified)"""
        self.search_count += 1
        self.logger.info(f"FIND_ALL(0x{item.data:x}): Completed")

    def check_sum(self, item):
        """Check SUM operation"""
        self.sum_count += 1

        expected_sum = sum(self.list_model)

        if item.result_data != expected_sum:
            self.logger.error(f"SUM: Mismatch! Expected={expected_sum} Actual={item.result_data}")
            self.error_count += 1
        else:
            self.logger.info(f"SUM: result={expected_sum} MATCH")

    def check_sort_asc(self, item):
        """Check SORT_ASC operation"""
        self.sort_count += 1
        self.list_model.sort()
        self.logger.info("SORT_ASC: Updated model")

    def check_sort_des(self, item):
        """Check SORT_DES operation"""
        self.sort_count += 1
        self.list_model.sort(reverse=True)
        self.logger.info("SORT_DES: Updated model")

    def report_phase(self):
        """Report statistics"""
        super().report_phase()
        self.logger.info("=" * 50)
        self.logger.info(f"Insert Count: {self.insert_count}")
        self.logger.info(f"Delete Count: {self.delete_count}")
        self.logger.info(f"Read Count: {self.read_count}")
        self.logger.info(f"Search Count: {self.search_count}")
        self.logger.info(f"Sort Count: {self.sort_count}")
        self.logger.info(f"Sum Count: {self.sum_count}")
        self.logger.info(f"Error Count: {self.error_count}")
        self.logger.info(f"Final List Size: {len(self.list_model)}")
        self.logger.info("=" * 50)

        if self.error_count > 0:
            self.logger.error(f"Test FAILED with {self.error_count} errors")
        else:
            self.logger.info("Test PASSED - No errors detected")
