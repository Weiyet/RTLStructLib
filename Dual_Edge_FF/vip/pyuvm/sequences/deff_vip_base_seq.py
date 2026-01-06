"""Dual Edge FF VIP Base Sequence"""
from pyuvm import *
from ..common.deff_vip_seq_item import DeffVipSeqItem

class DeffVipBaseSeq(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.cfg = None

    async def pre_body(self):
        self.cfg = ConfigDB().get(None, "", "deff_vip_cfg")

    async def body(self):
        pass
