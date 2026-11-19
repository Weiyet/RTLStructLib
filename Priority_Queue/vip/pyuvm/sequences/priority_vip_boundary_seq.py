from .priority_vip_base_seq import PriorityVipSequence


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
