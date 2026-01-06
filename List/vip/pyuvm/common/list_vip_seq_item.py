"""
List VIP Sequence Item
Create Date: 01/05/2026

Transaction item for List operations
"""

from pyuvm import *
import random
from .list_vip_types import ListOp


class ListVipSeqItem(uvm_sequence_item):
    """Sequence item for List transactions"""

    def __init__(self, name="list_vip_seq_item"):
        super().__init__(name)

        # Transaction fields
        self.op = ListOp.READ
        self.data = 0
        self.index = 0

        # Response fields
        self.result_data = 0    # For READ, FIND_1ST, FIND_ALL, SUM
        self.op_done = False
        self.op_in_progress = False
        self.op_error = False
        self.current_len = 0

        # Config reference
        self.cfg = None

    def randomize_with_op(self, op):
        """Randomize item with specific operation"""
        self.op = op

        if self.cfg:
            data_max = (1 << self.cfg.DATA_WIDTH) - 1
            index_max = self.cfg.LENGTH - 1
        else:
            data_max = 255
            index_max = 7

        self.data = random.randint(0, data_max)
        self.index = random.randint(0, index_max)

    def randomize(self):
        """Randomize all fields with distribution"""
        # Random operation with distribution
        op_choice = random.choices(
            [ListOp.READ, ListOp.INSERT, ListOp.DELETE, ListOp.FIND_1ST,
             ListOp.FIND_ALL, ListOp.SUM, ListOp.SORT_ASC, ListOp.SORT_DES, ListOp.IDLE],
            weights=[20, 30, 10, 10, 5, 10, 5, 5, 5]
        )[0]

        self.randomize_with_op(op_choice)

    def convert2string(self):
        """Convert to string for printing"""
        return (f"Op:{self.op.name} Data:0x{self.data:x} Index:{self.index} "
                f"Result:0x{self.result_data:x} Done:{self.op_done} "
                f"Error:{self.op_error} Len:{self.current_len}")
