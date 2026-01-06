"""
List VIP Sequencer
Create Date: 01/05/2026

Sequencer for List VIP
"""

from pyuvm import *
from ..common.list_vip_seq_item import ListVipSeqItem


class ListVipSequencer(uvm_sequencer):
    """Sequencer for List transactions"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    def build_phase(self):
        super().build_phase()
        self.logger.info(f"{self.get_name()} build_phase")
