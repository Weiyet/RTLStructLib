"""
FIFO VIP Read Request Sequence
Create Date: 01/05/2026
"""

from pyuvm import *
from .fifo_vip_base_seq import FifoVipBaseSeq
from ..common.fifo_vip_seq_item import FifoVipSeqItem
from ..common.fifo_vip_types import FifoOp
import random


class FifoVipReadReqSeq(FifoVipBaseSeq):
    """Read request sequence for FIFO VIP"""

    def __init__(self, name="fifo_vip_read_req_seq"):
        super().__init__(name)
        self.num_reads = random.randint(1, 20)

    async def body(self):
        """Sequence body"""
        self.logger.info(f"RD_SEQ: Starting {self.num_reads} reads")

        for i in range(self.num_reads):
            item = FifoVipSeqItem(f"rd_item_{i}")
            await self.start_item(item)
            item.randomize_with_op(FifoOp.READ)
            await self.finish_item(item)
