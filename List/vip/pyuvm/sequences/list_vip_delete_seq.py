"""
List VIP Delete Sequence
Create Date: 01/05/2026

Delete sequence for List VIP
"""

from pyuvm import *
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipDeleteSeq(ListVipBaseSeq):
    """Delete sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_deletes = 3  # default

    async def body(self):
        """Execute delete operations"""
        for i in range(self.num_deletes):
            item = ListVipSeqItem(f"delete_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(ListOp.DELETE)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Delete #{i}: index={item.index}")
