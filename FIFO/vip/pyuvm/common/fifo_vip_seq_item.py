"""
FIFO VIP Sequence Item
Create Date: 01/05/2026
"""

from pyuvm import *
from .fifo_vip_types import FifoOp
import random


class FifoVipSeqItem(uvm_sequence_item):
    """Sequence item for FIFO transactions"""

    def __init__(self, name="fifo_vip_seq_item"):
        super().__init__(name)
        # Transaction fields
        self.op = FifoOp.WRITE
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
        self.op = random.choice([FifoOp.WRITE, FifoOp.READ])

        # Randomize data based on config
        if self.cfg is not None:
            max_val = (1 << self.cfg.DATA_WIDTH) - 1
        else:
            max_val = 255  # 8-bit default

        self.data = random.randint(0, max_val)
        return True

    def randomize_with_op(self, op):
        """Randomize with specific operation"""
        self.op = op
        if self.cfg is not None:
            max_val = (1 << self.cfg.DATA_WIDTH) - 1
        else:
            max_val = 255
        self.data = random.randint(0, max_val)
        return True

    def set_config(self, cfg):
        """Set configuration reference"""
        self.cfg = cfg

    def convert2string(self):
        """Convert to string for printing"""
        return (f"Op:{self.op.name} Data:0x{self.data:x} ReadData:0x{self.read_data:x} "
                f"Full:{self.full} Empty:{self.empty} Success:{self.success}")

    def __str__(self):
        return self.convert2string()
