"""
Singly Linked List VIP Delete Sequence
Create Date: 01/05/2026

Delete sequence for Singly Linked List VIP
"""

from pyuvm import *
import random
from .sll_vip_base_seq import SllVipBaseSeq
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_types import SllOp


class SllVipDeleteSeq(SllVipBaseSeq):
    """Delete sequence for Singly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_deletes = 3  # default
        self.delete_mode = "addr"  # "addr", "index", or "value"

    async def body(self):
        """Execute delete operations"""
        for i in range(self.num_deletes):
            item = SllVipSeqItem(f"delete_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            # Select operation based on delete mode
            if self.delete_mode == "addr":
                op = SllOp.DELETE_AT_ADDR
            elif self.delete_mode == "index":
                op = SllOp.DELETE_AT_INDEX
            elif self.delete_mode == "value":
                op = SllOp.DELETE_VALUE
            else:
                # Random choice
                op = random.choice([SllOp.DELETE_AT_ADDR, SllOp.DELETE_AT_INDEX, SllOp.DELETE_VALUE])

            item.randomize_with_op(op)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Delete #{i}: {op.name} addr/data={item.addr}/{item.data}")
