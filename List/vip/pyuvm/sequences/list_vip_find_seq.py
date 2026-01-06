"""
List VIP Find Sequence
Create Date: 01/05/2026

Find sequence for List VIP
"""

from pyuvm import *
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipFindSeq(ListVipBaseSeq):
    """Find sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_finds = 3  # default
        self.find_all = False  # If True, use FIND_ALL; if False, use FIND_1ST

    async def body(self):
        """Execute find operations"""
        op = ListOp.FIND_ALL if self.find_all else ListOp.FIND_1ST

        for i in range(self.num_finds):
            item = ListVipSeqItem(f"find_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(op)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Find #{i}: data=0x{item.data:x} op={op.name}")
