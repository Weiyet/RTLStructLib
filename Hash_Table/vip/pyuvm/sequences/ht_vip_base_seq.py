"""Hash Table VIP Base Sequence"""
from pyuvm import *
from ..common.ht_vip_seq_item import HtVipSeqItem

class HtVipBaseSeq(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.cfg = None

    async def pre_body(self):
        self.cfg = ConfigDB().get(None, "", "ht_vip_cfg")

    async def body(self):
        pass
