"""
Doubly Linked List VIP Sequence Item
Create Date: 01/05/2026

Transaction item for Doubly Linked List operations
"""

from pyuvm import *
import random
from .dll_vip_types import DllOp


class DllVipSeqItem(uvm_sequence_item):
    """Sequence item for Doubly Linked List transactions"""

    def __init__(self, name="dll_vip_seq_item"):
        super().__init__(name)

        # Transaction fields
        self.op = DllOp.READ_ADDR
        self.data = 0
        self.addr = 0

        # Response fields
        self.result_data = 0
        self.result_pre_addr = 0   # Previous pointer (doubly linked)
        self.result_next_addr = 0  # Next pointer
        self.op_done = False
        self.fault = False
        self.current_len = 0
        self.current_head = 0
        self.current_tail = 0

        # Config reference
        self.cfg = None

    def randomize_with_op(self, op):
        """Randomize item with specific operation"""
        self.op = op

        if self.cfg:
            data_max = (1 << self.cfg.DATA_WIDTH) - 1
            addr_max = self.cfg.MAX_NODE
        else:
            data_max = 255
            addr_max = 8

        self.data = random.randint(0, data_max)
        self.addr = random.randint(0, addr_max)

    def randomize(self):
        """Randomize all fields with distribution"""
        # Random operation with distribution
        op_choice = random.choices(
            [DllOp.READ_ADDR, DllOp.INSERT_AT_ADDR, DllOp.INSERT_AT_INDEX,
             DllOp.DELETE_VALUE, DllOp.DELETE_AT_ADDR, DllOp.DELETE_AT_INDEX, DllOp.IDLE],
            weights=[20, 20, 20, 10, 15, 10, 5]
        )[0]

        self.randomize_with_op(op_choice)

    def convert2string(self):
        """Convert to string for printing"""
        return (f"Op:{self.op.name} Data:0x{self.data:x} Addr:{self.addr} "
                f"Result:0x{self.result_data:x} Done:{self.op_done} "
                f"Fault:{self.fault} Len:{self.current_len}")
