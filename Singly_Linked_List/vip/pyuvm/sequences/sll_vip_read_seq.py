"""
Singly Linked List VIP Read Sequence
Create Date: 01/05/2026

Read sequence for Singly Linked List VIP
"""

from pyuvm import *
from .sll_vip_base_seq import SllVipBaseSeq
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_types import SllOp


class SllVipReadSeq(SllVipBaseSeq):
    """Read sequence for Singly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_reads = 5  # default

    async def body(self):
        """Execute read operations"""
        for i in range(self.num_reads):
            item = SllVipSeqItem(f"read_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(SllOp.READ_ADDR)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Read #{i}: addr={item.addr}")
