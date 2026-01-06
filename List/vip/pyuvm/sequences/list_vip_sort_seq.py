"""
List VIP Sort Sequence
Create Date: 01/05/2026

Sort sequence for List VIP
"""

from pyuvm import *
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipSortSeq(ListVipBaseSeq):
    """Sort sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.ascending = True  # If True, sort ascending; if False, descending

    async def body(self):
        """Execute sort operation"""
        op = ListOp.SORT_ASC if self.ascending else ListOp.SORT_DES

        item = ListVipSeqItem("sort_item")
        if self.cfg:
            item.cfg = self.cfg

        item.randomize_with_op(op)

        await self.start_item(item)
        await self.finish_item(item)

        self.logger.info(f"Sort: {op.name}")
