import random
from pyuvm import uvm_sequence
from .common import PriorityVipItem


class PriorityVipSequence(uvm_sequence):
    def __init__(self, name, cfg):
        super().__init__(name)
        self.cfg = cfg

    async def send(self, **kwargs):
        item = PriorityVipItem(**kwargs)
        await self.start_item(item)
        await self.finish_item(item)
        return item


class PriorityVipBoundarySequence(PriorityVipSequence):
    async def body(self):
        await self.send(reset=True)
        for op in (1, 2, 3):
            await self.send(op=op, stalls=3)
        for pattern in (range(self.cfg.depth), reversed(range(self.cfg.depth)), [0] * self.cfg.depth):
            for i, priority in enumerate(pattern):
                await self.send(priority=priority, data=i, stalls=i % 3)
            await self.send(op=0, stalls=2)
            await self.send(op=3)
            for _ in range(self.cfg.depth):
                first = await self.send(op=2)
                second = await self.send(op=2, stalls=2)
                removed = await self.send(op=1, stalls=1)
                assert first.response == second.response == removed.response
        await self.send(op=1)


class PriorityVipRandomSequence(PriorityVipSequence):
    async def body(self):
        rng = random.Random(self.cfg.seed)
        await self.send(reset=True)
        for _ in range(400):
            await self.send(op=rng.choices((0, 1, 2, 3), (45, 35, 15, 5))[0],
                            priority=rng.getrandbits(self.cfg.priority_width),
                            data=rng.getrandbits(self.cfg.data_width), stalls=rng.randrange(5))
        for _ in range(self.cfg.depth + 1):
            await self.send(op=1)


class PriorityVipResetSequence(PriorityVipSequence):
    async def body(self):
        for op in (0, 1, 2):
            for delay in range(self.cfg.depth.bit_length() + 2):
                await self.send(reset=True)
                for i in range(max(1, self.cfg.depth - 1)):
                    await self.send(priority=i, data=i)
                await self.send(op=op, priority=0 if self.cfg.min_first else (1 << self.cfg.priority_width)-1,
                                data=(1 << self.cfg.data_width)-1, abort_after=delay)
                await self.send(op=1)  # reset discarded all entries
                await self.send(priority=(1 << self.cfg.priority_width)-1,
                                data=(1 << self.cfg.data_width)-1)
                await self.send(op=1)
