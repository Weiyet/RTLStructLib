from pyuvm import uvm_sequence
from ..common.priority_vip_seq_item import PriorityVipItem


class PriorityVipSequence(uvm_sequence):
    def __init__(self, name, cfg):
        super().__init__(name)
        self.cfg = cfg

    async def send(self, **kwargs):
        item = PriorityVipItem(**kwargs)
        await self.start_item(item)
        await self.finish_item(item)
        return item
