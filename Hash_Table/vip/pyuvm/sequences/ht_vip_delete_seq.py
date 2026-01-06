"""Hash Table VIP Delete Sequence"""
from pyuvm import *
from .ht_vip_base_seq import HtVipBaseSeq
from ..common.ht_vip_seq_item import HtVipSeqItem
from ..common.ht_vip_types import HtOp

class HtVipDeleteSeq(HtVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)
        self.num_deletes = 3

    async def body(self):
        for i in range(self.num_deletes):
            item = HtVipSeqItem(f"delete_{i}")
            if self.cfg:
                item.cfg = self.cfg
            item.randomize_with_op(HtOp.DELETE)
            await self.start_item(item)
            await self.finish_item(item)
            self.logger.info(f"Delete #{i}: key=0x{item.key:x}")
