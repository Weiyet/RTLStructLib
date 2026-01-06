"""Table VIP Read Sequence"""
from .table_vip_base_seq import TableVipBaseSeq
from ..common.table_vip_seq_item import TableVipSeqItem
from ..common import TableOp

class TableVipReadSeq(TableVipBaseSeq):
    def __init__(self, name):
        super().__init__(name)

    async def body(self):
        """Generate READ transactions"""
        for i in range(self.num_trans):
            item = TableVipSeqItem(f"read_item_{i}")
            item.cfg = self.cfg
            item.op = TableOp.READ
            item.randomize()
            await self.start_item(item)
            await self.finish_item(item)
