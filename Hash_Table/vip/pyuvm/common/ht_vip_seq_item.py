"""
Hash Table VIP Sequence Item
Create Date: 01/05/2026

Transaction item for Hash Table operations (key-value pairs)
"""

from pyuvm import *
import random
from .ht_vip_types import HtOp


class HtVipSeqItem(uvm_sequence_item):
    """Sequence item for Hash Table transactions"""

    def __init__(self, name="ht_vip_seq_item"):
        super().__init__(name)

        # Transaction fields (key-value pairs)
        self.op = HtOp.INSERT
        self.key = 0
        self.value = 0

        # Response fields
        self.result_value = 0
        self.op_done = False
        self.op_error = False
        self.collision_count = 0

        # Config reference
        self.cfg = None

    def randomize_with_op(self, op):
        """Randomize item with specific operation"""
        self.op = op

        if self.cfg:
            key_max = (1 << self.cfg.KEY_WIDTH) - 1
            value_max = (1 << self.cfg.VALUE_WIDTH) - 1
        else:
            key_max = 0xFFFFFFFF
            value_max = 0xFFFFFFFF

        # Key should not be 0
        self.key = random.randint(1, key_max)
        self.value = random.randint(0, value_max)

    def randomize(self):
        """Randomize all fields with distribution"""
        # Random operation with distribution
        op_choice = random.choices(
            [HtOp.INSERT, HtOp.DELETE, HtOp.SEARCH],
            weights=[40, 30, 30]
        )[0]

        self.randomize_with_op(op_choice)

    def convert2string(self):
        """Convert to string for printing"""
        return (f"Op:{self.op.name} Key:0x{self.key:x} Value:0x{self.value:x} "
                f"Result:0x{self.result_value:x} Done:{self.op_done} "
                f"Error:{self.op_error} Collisions:{self.collision_count}")
