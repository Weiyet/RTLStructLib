"""
Doubly Linked List VIP Delete Sequence
Create Date: 01/05/2026

Delete sequence for Doubly Linked List VIP
"""

from pyuvm import *
import random
from .dll_vip_base_seq import DllVipBaseSeq
from ..common.dll_vip_seq_item import DllVipSeqItem
from ..common.dll_vip_types import DllOp


class DllVipDeleteSeq(DllVipBaseSeq):
    """Delete sequence for Doubly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_deletes = 3  # default
        self.delete_mode = "addr"  # "addr", "index", or "value"

    async def body(self):
        """Execute delete operations"""
        for i in range(self.num_deletes):
            item = DllVipSeqItem(f"delete_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            # Select operation based on delete mode
            if self.delete_mode == "addr":
                op = DllOp.DELETE_AT_ADDR
            elif self.delete_mode == "index":
                op = DllOp.DELETE_AT_INDEX
            elif self.delete_mode == "value":
                op = DllOp.DELETE_VALUE
            else:
                # Random choice
                op = random.choice([DllOp.DELETE_AT_ADDR, DllOp.DELETE_AT_INDEX, DllOp.DELETE_VALUE])

            item.randomize_with_op(op)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Delete #{i}: {op.name} addr/data={item.addr}/{item.data}")
