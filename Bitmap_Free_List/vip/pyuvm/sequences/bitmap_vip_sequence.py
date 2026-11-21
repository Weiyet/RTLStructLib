import random
from pyuvm import uvm_sequence
from ..common.bitmap_vip_seq_item import BitmapVipItem


class BitmapVipSequence(uvm_sequence):
    def __init__(self, name, cfg, scenario="boundary"):
        super().__init__(name)
        self.cfg = cfg
        self.scenario = scenario

    async def send(self, allocate=0, release=0, ident=0, reset=0):
        item = BitmapVipItem(allocate=allocate, release=release, ident=ident, reset=reset)
        await self.start_item(item)
        await self.finish_item(item)
        return item

    async def body(self):
        cap = self.cfg.capacity
        await self.send(1, 1, 0, 1)
        await self.send()
        if self.scenario == "random":
            rng = random.Random(self.cfg.seed)
            for i in range(600):
                await self.send(rng.randrange(2), rng.randrange(2),
                                rng.randrange(1 << self.cfg.id_width), (i % 113) == 112)
        elif self.scenario == "reset":
            for _ in range(3):
                for _ in range(cap):
                    await self.send(1)
                await self.send(1, 1, cap - 1, 1)
                await self.send()
                await self.send(1)
                await self.send(1, 1, 0)
                await self.send(reset=1)
        else:
            await self.send(0, 1, 0)
            await self.send(1, 1, 0)
            await self.send(0, 1, 0)
            for _ in range(2):
                for _ in range(cap + 1):
                    await self.send(1)
                for ident in reversed(range(cap)):
                    await self.send(1, 1, ident)
                for ident in reversed(range(cap)):
                    await self.send(0, 1, ident)
                    await self.send(0, 1, ident)
            for ident in range(cap, 1 << self.cfg.id_width):
                await self.send(0, 1, ident)
                await self.send(1, 1, ident)
            await self.send(reset=1)
            for _ in range(cap):
                await self.send(1)
            await self.send(0, 1, 0)
            await self.send(1, 1, cap - 1)
        await self.send(1, 1, 0, 1)
        for _ in range(cap + 1):
            await self.send(1)
        for ident in range(cap):
            await self.send(0, 1, ident)
        await self.send()
