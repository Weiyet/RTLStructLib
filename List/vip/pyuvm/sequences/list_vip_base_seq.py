"""
List VIP Base Sequence
Create Date: 01/05/2026

Base sequence class for List VIP
"""

from pyuvm import *
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_config import ListVipConfig


class ListVipBaseSeq(uvm_sequence):
    """Base sequence for List VIP"""

    def __init__(self, name):
        super().__init__(name)
        self.cfg = None

    async def pre_body(self):
        """Get config before sequence starts"""
        self.cfg = ConfigDB().get(None, "", "list_vip_cfg")

    async def body(self):
        """Override in derived classes"""
        pass
