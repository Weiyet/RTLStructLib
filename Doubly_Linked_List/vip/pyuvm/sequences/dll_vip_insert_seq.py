"""
Doubly Linked List VIP Insert Sequence
Create Date: 01/05/2026

Insert sequence for Doubly Linked List VIP
"""

from pyuvm import *
from .dll_vip_base_seq import DllVipBaseSeq
from ..common.dll_vip_seq_item import DllVipSeqItem
from ..common.dll_vip_types import DllOp


class DllVipInsertSeq(DllVipBaseSeq):
    """Insert sequence for Doubly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.num_inserts = 5  # default
        self.use_index = False  # If False, use INSERT_AT_ADDR; if True, use INSERT_AT_INDEX

    async def body(self):
        """Execute insert operations"""
        op = DllOp.INSERT_AT_INDEX if self.use_index else DllOp.INSERT_AT_ADDR

        for i in range(self.num_inserts):
            item = DllVipSeqItem(f"insert_item_{i}")
            if self.cfg:
                item.cfg = self.cfg

            item.randomize_with_op(op)

            await self.start_item(item)
            await self.finish_item(item)

            self.logger.info(f"Insert #{i}: data=0x{item.data:x} addr={item.addr}")
