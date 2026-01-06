"""Dual Edge FF VIP Sequence Item"""
from pyuvm import *
import random

class DeffVipSeqItem(uvm_sequence_item):
    def __init__(self, name="deff_vip_seq_item"):
        super().__init__(name)
        self.data_in = 0
        self.pos_edge_latch_en = 0
        self.neg_edge_latch_en = 0
        self.data_out = 0
        self.cfg = None

    def randomize(self):
        if self.cfg:
            data_max = (1 << self.cfg.DATA_WIDTH) - 1
        else:
            data_max = 0xFF

        self.data_in = random.randint(0, data_max)
        self.pos_edge_latch_en = random.randint(0, data_max)
        self.neg_edge_latch_en = random.randint(0, data_max)

        # Ensure at least one latch enable is active
        if (self.pos_edge_latch_en | self.neg_edge_latch_en) == 0:
            self.pos_edge_latch_en = random.randint(1, data_max)

    def convert2string(self):
        return f"data_in=0x{self.data_in:x} pos_en=0x{self.pos_edge_latch_en:x} neg_en=0x{self.neg_edge_latch_en:x} data_out=0x{self.data_out:x}"
