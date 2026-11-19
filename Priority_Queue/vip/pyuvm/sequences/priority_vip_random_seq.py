import random
from .priority_vip_base_seq import PriorityVipSequence


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
