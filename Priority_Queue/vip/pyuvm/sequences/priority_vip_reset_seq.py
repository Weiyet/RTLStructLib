from .priority_vip_base_seq import PriorityVipSequence


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
