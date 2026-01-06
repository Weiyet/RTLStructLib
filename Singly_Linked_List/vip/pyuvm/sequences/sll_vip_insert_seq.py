"""
Singly Linked List VIP Insert Sequence
Create Date: 01/05/2026

Insert sequence for Singly Linked List VIP
"""

from pyuvm import *
from .sll_vip_base_seq import SllVipBaseSeq
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_types import SllOp


class SllVipInsertSeq(SllVipBaseSeq):
    """Insert sequence for Singly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_inserts = 5  # default
        self.use_index = False  # If False, use INSERT_AT_ADDR; if True, use INSERT_AT_INDEX

    async def body(self):
        """Execute insert operations"""
        op = SllOp.INSERT_AT_INDEX if self.use_index else SllOp.INSERT_AT_ADDR

        for i in range(self.num_inserts):
            item = SllVipSeqItem(f"insert_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(op)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Insert #{i}: data=0x{item.data:x} addr={item.addr}")
