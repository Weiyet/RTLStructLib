"""LIFO VIP Pop Sequence"""
from .lifo_vip_base_seq import LifoVipBaseSeq
from ..common.lifo_vip_seq_item import LifoVipSeqItem
from ..common import LifoOp

class LifoVipPopSeq(LifoVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Generate POP transactions"""
        for i in range(self.num_trans):
            item = LifoVipSeqItem(f"pop_item_{i}")
            item.cfg = self.cfg
            item.op = LifoOp.POP
            await self.start_item(item)
            await self.finish_item(item)
