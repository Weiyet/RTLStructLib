"""
Doubly Linked List VIP Sequencer
Create Date: 01/05/2026

Sequencer for Doubly Linked List VIP
"""

from pyuvm import *
from ..common.dll_vip_seq_item import DllVipSeqItem


class DllVipSequencer(uvm_sequencer):
    """Sequencer for Doubly Linked List transactions"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    def build_phase(self):
        super().build_phase()
        self.logger.info(f"{self.get_name()} build_phase")
