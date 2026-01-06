"""
List VIP Read Sequence
Create Date: 01/05/2026

Read sequence for List VIP
"""

from pyuvm import *
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipReadSeq(ListVipBaseSeq):
    """Read sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_reads = 5  # default

    async def body(self):
        """Execute read operations"""
        for i in range(self.num_reads):
            item = ListVipSeqItem(f"read_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(ListOp.READ)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Read #{i}: index={item.index}")
