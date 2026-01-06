"""Dual Edge FF VIP Random Sequence"""
from pyuvm import *
from .deff_vip_base_seq import DeffVipBaseSeq
from ..common.deff_vip_seq_item import DeffVipSeqItem

class DeffVipRandomSeq(DeffVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)
        self.num_trans = 10

    async def body(self):
        for i in range(self.num_trans):
            item = DeffVipSeqItem(f"trans_{i}")
            if self.cfg:
                item.cfg = self.cfg
            item.randomize()
            await self.start_item(item)
            await self.finish_item(item)
            self.logger.info(f"Trans #{i}: {item.convert2string()}")
