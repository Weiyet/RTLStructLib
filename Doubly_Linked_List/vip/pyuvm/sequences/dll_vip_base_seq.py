"""
Doubly Linked List VIP Base Sequence
Create Date: 01/05/2026

Base sequence class for Doubly Linked List VIP
"""

from pyuvm import *
from ..common.dll_vip_seq_item import DllVipSeqItem
from ..common.dll_vip_config import DllVipConfig


class DllVipBaseSeq(uvm_sequence):
    """Base sequence for Doubly Linked List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.cfg = None

    async def pre_body(self):
        """Get config before sequence starts"""
        self.cfg = ConfigDB().get(None, "", "dll_vip_cfg")

    async def body(self):
        """Override in derived classes"""
        pass
