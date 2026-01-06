"""LIFO VIP Sequence Item"""
from pyuvm import uvm_sequence_item
from .import LifoOp
import random

class LifoVipSeqItem(uvm_sequence_item):
    def __init__(self, name="lifo_vip_seq_item"):
        super().__init__(name)
        # Transaction fields
        self.op = LifoOp.PUSH
        self.data = 0

        # Response fields
        self.read_data = 0
        self.full = False
        self.empty = False
        self.success = True

        # Config reference
        self.cfg = None

    def randomize(self):
        """Randomize transaction fields"""
        # Randomize operation
        self.op = random.choice([LifoOp.PUSH, LifoOp.POP])

        # Randomize data
        if self.cfg:
            max_val = (1 << self.cfg.DATA_WIDTH) - 1
        else:
            max_val = 255  # 8-bit default
        self.data = random.randint(0, max_val)

        return True

    def __str__(self):
        op_name = self.op.name if hasattr(self.op, 'name') else str(self.op)
        return (f"Op:{op_name} Data:0x{self.data:x} "
                f"ReadData:0x{self.read_data:x} Full:{self.full} "
                f"Empty:{self.empty} Success:{self.success}")
