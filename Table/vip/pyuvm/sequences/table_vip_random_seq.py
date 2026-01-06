"""Table VIP Random Sequence"""
from .table_vip_base_seq import TableVipBaseSeq
from ..common.table_vip_seq_item import TableVipSeqItem

class TableVipRandomSeq(TableVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Generate random READ/WRITE transactions"""
        for i in range(self.num_trans):
            item = TableVipSeqItem(f"rand_item_{i}")
            item.cfg = self.cfg
            item.randomize()  # Randomizes op and data
            await self.start_item(item)
            await self.finish_item(item)
