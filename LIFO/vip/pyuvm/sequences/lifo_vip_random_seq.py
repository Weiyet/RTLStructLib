"""LIFO VIP Random Sequence"""
from .lifo_vip_base_seq import LifoVipBaseSeq
from ..common.lifo_vip_seq_item import LifoVipSeqItem

class LifoVipRandomSeq(LifoVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Generate random PUSH/POP transactions"""
        for i in range(self.num_trans):
            item = LifoVipSeqItem(f"rand_item_{i}")
            item.cfg = self.cfg
            item.randomize()  # Randomizes op and data
            await self.start_item(item)
            await self.finish_item(item)
