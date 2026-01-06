"""
List VIP Insert Sequence
Create Date: 01/05/2026

Insert sequence for List VIP
"""

from pyuvm import *
import random
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipInsertSeq(ListVipBaseSeq):
    """Insert sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_inserts = 5  # default
        self.random_index = False  # If False, append at end

    async def body(self):
        """Execute insert operations"""
        for i in range(self.num_inserts):
            item = ListVipSeqItem(f"insert_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            if self.random_index:
                item.randomize_with_op(ListOp.INSERT)
            else:
                item.randomize_with_op(ListOp.INSERT)
                item.index = 0xFFFF  # Large index = append at end

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Insert #{i}: data=0x{item.data:x} index={item.index}")
