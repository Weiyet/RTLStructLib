"""
FIFO VIP Write Request Sequence
Create Date: 01/05/2026
"""

from pyuvm import *
from .fifo_vip_base_seq import FifoVipBaseSeq
from ..common.fifo_vip_seq_item import FifoVipSeqItem
from ..common.fifo_vip_types import FifoOp
import random


class FifoVipWriteReqSeq(FifoVipBaseSeq):
    """Write request sequence for FIFO VIP"""

    def __init__(self, name="fifo_vip_write_req_seq"):
        super().__init__(name)
        self.num_writes = random.randint(1, 20)

    async def body(self):
        """Sequence body"""
        self.logger.info(f"WR_SEQ: Starting {self.num_writes} writes")

        for i in range(self.num_writes):
            item = FifoVipSeqItem(f"wr_item_{i}")
            await self.start_item(item)
            item.randomize_with_op(FifoOp.WRITE)
            await self.finish_item(item)
