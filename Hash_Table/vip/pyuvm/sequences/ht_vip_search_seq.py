"""Hash Table VIP Search Sequence"""
from pyuvm import *
from .ht_vip_base_seq import HtVipBaseSeq
from ..common.ht_vip_seq_item import HtVipSeqItem
from ..common.ht_vip_types import HtOp

class HtVipSearchSeq(HtVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)
        self.num_searches = 5

    async def body(self):
        for i in range(self.num_searches):
            item = HtVipSeqItem(f"search_{i}")
            if self.cfg:
                item.cfg = self.cfg
            item.randomize_with_op(HtOp.SEARCH)
            await self.start_item(item)
            await self.finish_item(item)
            self.logger.info(f"Search #{i}: key=0x{item.key:x}")
