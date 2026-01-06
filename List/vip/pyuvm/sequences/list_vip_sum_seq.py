"""
List VIP Sum Sequence
Create Date: 01/05/2026

Sum sequence for List VIP
"""

from pyuvm import *
from .list_vip_base_seq import ListVipBaseSeq
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp


class ListVipSumSeq(ListVipBaseSeq):
    """Sum sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Execute sum operation"""
        item = ListVipSeqItem("sum_item")
        if self.cfg:
            item.cfg = self.cfg

        item.randomize_with_op(ListOp.SUM)

        await self.start_item(item)
        await self.finish_item(item)

        self.logger.info(f"Sum: result={item.result_data}")
