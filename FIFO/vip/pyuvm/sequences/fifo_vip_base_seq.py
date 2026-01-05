"""
FIFO VIP Base Sequence
Create Date: 01/05/2026
"""

from pyuvm import *


class FifoVipBaseSeq(uvm_sequence):
    """Base sequence for FIFO VIP"""

    def __init__(self, name="fifo_vip_base_seq"):
        super().__init__(name)
