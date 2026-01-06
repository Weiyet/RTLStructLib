"""Table VIP Sequencer"""
from pyuvm import uvm_sequencer
from ..common.table_vip_seq_item import TableVipSeqItem

class TableVipSequencer(uvm_sequencer):
    def __init__(self, name, parent):
        super().__init__(name, parent)
