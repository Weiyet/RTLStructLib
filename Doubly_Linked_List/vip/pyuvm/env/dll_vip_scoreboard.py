"""
Doubly Linked List VIP Scoreboard
Create Date: 01/05/2026

Scoreboard for Doubly Linked List VIP - self-checking component with list model
Note: Tracks both prev and next pointers for doubly linked list
"""

from pyuvm import *
from ..common.dll_vip_seq_item import DllVipSeqItem
from ..common.dll_vip_types import DllOp
from ..common.dll_vip_config import DllVipConfig


class DllVipScoreboard(uvm_scoreboard):
    """Scoreboard for Doubly Linked List VIP with reference model"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.imp = uvm_analysis_export("imp", self)
        self.cfg = None

        # Reference model: queues to track list data and addresses
        self.list_data = []
        self.list_addr = []
        self.expected_length = 0
        self.expected_head = 0
        self.expected_tail = 0
        self.error_count = 0

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "dll_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    def connect_phase(self):
        super().connect_phase()
        self.imp.connect(self)

    def write(self, item):
        """Analysis write method - called by monitor"""
        self.logger.info(f"Checking: {item.convert2string()}")

        if item.op == DllOp.INSERT_AT_ADDR:
            self.check_insert_at_addr(item)
        elif item.op == DllOp.INSERT_AT_INDEX:
            self.check_insert_at_index(item)
        elif item.op == DllOp.READ_ADDR:
            self.check_read_addr(item)
        elif item.op == DllOp.DELETE_VALUE:
            self.check_delete_value(item)
        elif item.op == DllOp.DELETE_AT_ADDR:
            self.check_delete_at_addr(item)
        elif item.op == DllOp.DELETE_AT_INDEX:
            self.check_delete_at_index(item)
        elif item.op == DllOp.IDLE:
            self.logger.debug("IDLE operation, no checking")

        # Check list state
        if item.current_len != self.expected_length:
            self.logger.error(f"Length mismatch: expected={self.expected_length}, actual={item.current_len}")
            self.error_count += 1

    def check_insert_at_addr(self, item):
        """Check INSERT_AT_ADDR operation"""
        if item.fault:
            self.logger.info("Insert at addr faulted (expected for invalid addr)")
            return

        idx = -1
        for i, addr in enumerate(self.list_addr):
            if addr == item.addr:
                idx = i
                break

        if item.addr == 0 or idx == -1:
            self.list_data.insert(0, item.data)
            self.list_addr.insert(0, self.expected_length + 1 if item.addr == 0 else item.addr)
            self.expected_head = self.list_addr[0]
        else:
            self.list_data.insert(idx + 1, item.data)
            self.list_addr.insert(idx + 1, self.expected_length + 1)

        if len(self.list_data) == 1:
            self.expected_tail = self.list_addr[0]
        else:
            self.expected_tail = self.list_addr[-1]

        self.expected_length += 1
        self.logger.debug(f"Inserted data=0x{item.data:x} at addr={item.addr}")

    def check_insert_at_index(self, item):
        """Check INSERT_AT_INDEX operation"""
        if item.fault:
            self.logger.info("Insert at index faulted (expected for invalid index)")
            return

        if item.addr >= len(self.list_data):
            self.list_data.append(item.data)
            self.list_addr.append(self.expected_length + 1)
            self.expected_tail = self.list_addr[-1]
        else:
            self.list_data.insert(item.addr, item.data)
            self.list_addr.insert(item.addr, self.expected_length + 1)

        if len(self.list_data) == 1:
            self.expected_head = self.list_addr[0]
            self.expected_tail = self.list_addr[0]

        self.expected_length += 1
        self.logger.debug(f"Inserted data=0x{item.data:x} at index={item.addr}")

    def check_read_addr(self, item):
        """Check READ_ADDR operation - verify both prev and next pointers"""
        if item.fault:
            self.logger.info("Read faulted (expected for invalid addr)")
            return

        idx = -1
        for i, addr in enumerate(self.list_addr):
            if addr == item.addr:
                idx = i
                break

        if idx != -1:
            if item.result_data != self.list_data[idx]:
                self.logger.error(f"Read data mismatch at addr={item.addr}: expected=0x{self.list_data[idx]:x}, actual=0x{item.result_data:x}")
                self.error_count += 1

            # Check prev pointer (doubly linked)
            if idx > 0:
                if item.result_pre_addr != self.list_addr[idx - 1]:
                    self.logger.error(f"Prev addr mismatch: expected={self.list_addr[idx - 1]}, actual={item.result_pre_addr}")
                    self.error_count += 1
            else:
                if item.result_pre_addr != 0:
                    self.logger.error(f"Expected pre_addr=0 for head, got {item.result_pre_addr}")
                    self.error_count += 1

            # Check next pointer
            if idx < len(self.list_addr) - 1:
                if item.result_next_addr != self.list_addr[idx + 1]:
                    self.logger.error(f"Next addr mismatch: expected={self.list_addr[idx + 1]}, actual={item.result_next_addr}")
                    self.error_count += 1
            else:
                if item.result_next_addr != 0:
                    self.logger.error(f"Expected next_addr=0 for tail, got {item.result_next_addr}")
                    self.error_count += 1
        else:
            self.logger.error(f"Address {item.addr} not found in model")
            self.error_count += 1

    def check_delete_value(self, item):
        """Check DELETE_VALUE operation"""
        if item.fault:
            self.logger.info("Delete value faulted (value not found)")
            return

        idx = -1
        for i, data in enumerate(self.list_data):
            if data == item.data:
                idx = i
                break

        if idx != -1:
            del self.list_data[idx]
            del self.list_addr[idx]
            self.expected_length -= 1

            if len(self.list_data) == 0:
                self.expected_head = 0
                self.expected_tail = 0
            else:
                self.expected_head = self.list_addr[0]
                self.expected_tail = self.list_addr[-1]
            self.logger.debug(f"Deleted value=0x{item.data:x}")

    def check_delete_at_addr(self, item):
        """Check DELETE_AT_ADDR operation"""
        if item.fault:
            self.logger.info("Delete at addr faulted (invalid addr)")
            return

        idx = -1
        for i, addr in enumerate(self.list_addr):
            if addr == item.addr:
                idx = i
                break

        if idx != -1:
            del self.list_data[idx]
            del self.list_addr[idx]
            self.expected_length -= 1

            if len(self.list_data) == 0:
                self.expected_head = 0
                self.expected_tail = 0
            else:
                self.expected_head = self.list_addr[0]
                self.expected_tail = self.list_addr[-1]
            self.logger.debug(f"Deleted at addr={item.addr}")

    def check_delete_at_index(self, item):
        """Check DELETE_AT_INDEX operation"""
        if item.fault:
            self.logger.info("Delete at index faulted (invalid index)")
            return

        if item.addr < len(self.list_data):
            del self.list_data[item.addr]
            del self.list_addr[item.addr]
            self.expected_length -= 1

            if len(self.list_data) == 0:
                self.expected_head = 0
                self.expected_tail = 0
            else:
                self.expected_head = self.list_addr[0]
                self.expected_tail = self.list_addr[-1]
            self.logger.debug(f"Deleted at index={item.addr}")

    def report_phase(self):
        """Report statistics"""
        super().report_phase()
        self.logger.info("=" * 50)
        self.logger.info(f"Error Count: {self.error_count}")
        self.logger.info(f"Final List Size: {len(self.list_data)}")
        self.logger.info("=" * 50)

        if self.error_count > 0:
            self.logger.error(f"Test FAILED with {self.error_count} errors")
        else:
            self.logger.info("Test PASSED - No errors detected")
