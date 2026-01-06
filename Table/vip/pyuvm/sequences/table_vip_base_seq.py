"""Table VIP Base Sequence"""
from pyuvm import uvm_sequence
from ..common.table_vip_seq_item import TableVipSeqItem

class TableVipBaseSeq(uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.num_trans = 10
        self.cfg = None

    async def body(self):
        """Sequence body - override in derived classes"""
        pass
