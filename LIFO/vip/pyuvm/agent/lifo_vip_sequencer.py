"""LIFO VIP Sequencer"""
from pyuvm import uvm_sequencer
from ..common.lifo_vip_seq_item import LifoVipSeqItem

class LifoVipSequencer(uvm_sequencer):
    def __init__(self, name, parent):
        super().__init__(name, parent)
