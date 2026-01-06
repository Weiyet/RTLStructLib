"""
Singly Linked List VIP Base Sequence
Create Date: 01/05/2026

Base sequence class for Singly Linked List VIP
"""

from pyuvm import *
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_config import SllVipConfig


class SllVipBaseSeq(uvm_sequence):
    """Base sequence for Singly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.cfg = None

    async def pre_body(self):
        """Get config before sequence starts"""
        self.cfg = ConfigDB().get(None, "", "sll_vip_cfg")

    async def body(self):
        """Override in derived classes"""
        pass
