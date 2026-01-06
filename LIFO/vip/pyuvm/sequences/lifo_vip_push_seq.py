"""LIFO VIP Push Sequence"""
from .lifo_vip_base_seq import LifoVipBaseSeq
from ..common.lifo_vip_seq_item import LifoVipSeqItem
from ..common import LifoOp

class LifoVipPushSeq(LifoVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Generate PUSH transactions"""
        for i in range(self.num_trans):
            item = LifoVipSeqItem(f"push_item_{i}")
            item.cfg = self.cfg
            item.op = LifoOp.PUSH
            item.randomize()
            await self.start_item(item)
            await self.finish_item(item)
