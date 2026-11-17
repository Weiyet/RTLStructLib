"""Port-only multiset scoreboard; does not reproduce the heap implementation."""
import os
import random

import cocotb
from cocotb.triggers import Timer


class Queue:
    def __init__(self, dut):
        self.dut = dut
        self.depth = int(dut.DEPTH.value)
        self.min_first = int(dut.MIN_FIRST.value)
        self.pwidth = len(dut.req_priority)
        self.dwidth = len(dut.req_data)
        self.pmask = (1 << self.pwidth) - 1
        self.dmask = (1 << self.dwidth) - 1
        self.items = []
        self.cycles = 0
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "100000"))
        self.rng = random.Random(int(os.getenv("TB_SEED", "123")))

    async def tick(self):
        self.cycles += 1
        assert self.cycles <= self.limit, "Priority Queue timed out"
        self.dut.clk.value = 0
        await Timer(5, units="ns")
        self.dut.clk.value = 1
        await Timer(5, units="ns")

    def flags(self):
        assert int(self.dut.count.value) == len(self.items)
        assert int(self.dut.full.value) == (len(self.items) == self.depth)
        assert int(self.dut.empty.value) == (not self.items)

    async def reset(self):
        d = self.dut
        d.clk.value = 0
        d.rst.value = 0
        d.req_valid.value = 0
        d.rsp_ready.value = 0
        d.req_op.value = 0
        d.req_priority.value = 0
        d.req_data.value = 0
        await Timer(2, units="ns")
        d.rst.value = 1
        await Timer(2, units="ns")
        self.items.clear()
        self.flags()
        assert not int(d.req_ready.value) and not int(d.rsp_valid.value)
        assert int(d.rsp_data.value) == int(d.rsp_priority.value) == int(d.rsp_error.value) == 0
        await self.tick()
        d.rst.value = 0
        await self.tick()
        assert int(d.req_ready.value)

    async def command(self, op, priority=0, data=0, stall=0):
        d = self.dut
        priority &= self.pmask
        data &= self.dmask
        assert int(d.req_ready.value)
        error = op == 3 or (op == 0 and len(self.items) == self.depth) or (op in (1, 2) and not self.items)
        expected_priority = None
        if not error and op in (1, 2):
            expected_priority = (min if self.min_first else max)(p for p, _ in self.items)
        d.req_valid.value = 1
        d.req_op.value = op
        d.req_priority.value = priority
        d.req_data.value = data
        d.rsp_ready.value = 0
        await self.tick()
        # Poison inputs and keep valid asserted while busy: no extra acceptance.
        d.req_op.value = 3
        d.req_priority.value = priority ^ self.pmask
        d.req_data.value = data ^ self.dmask
        for latency in range(self.depth.bit_length() + 3):
            assert not int(d.req_ready.value)
            if int(d.rsp_valid.value):
                break
            await self.tick()
        else:
            raise AssertionError("Operation timed out")
        actual = (int(d.rsp_priority.value), int(d.rsp_data.value))
        assert int(d.rsp_error.value) == error
        if error or op == 0:
            assert actual == (0, 0)
        else:
            assert actual[0] == expected_priority and actual in self.items, (actual, self.items)
            if op == 1:
                self.items.remove(actual)
        if not error and op == 0:
            self.items.append((priority, data))
        self.flags()
        for _ in range(stall):
            await self.tick()
            assert int(d.rsp_valid.value) and not int(d.req_ready.value)
            assert actual == (int(d.rsp_priority.value), int(d.rsp_data.value))
            assert int(d.rsp_error.value) == error
            self.flags()
        d.rsp_ready.value = 1
        await self.tick()  # request valid was high, but pre-edge ready was low
        d.req_valid.value = 0
        assert int(d.req_ready.value) and not int(d.rsp_valid.value)
        await self.tick()
        assert int(d.req_ready.value) and not int(d.rsp_valid.value)
        self.flags()
        return actual


@cocotb.test()
async def test_empty_and_invalid(dut):
    q = Queue(dut)
    await q.reset()
    for op in (1, 2, 3, 1):
        await q.command(op, stall=3)


@cocotb.test()
async def test_order_and_capacity(dut):
    q = Queue(dut)
    await q.reset()
    for pattern in (range(q.depth), reversed(range(q.depth)), [q.pmask] * q.depth):
        for i, priority in enumerate(pattern):
            await q.command(0, priority, i)
        await q.command(0, 0, 0)
        await q.command(3)
        for _ in range(q.depth):
            first = await q.command(2)
            assert await q.command(2) == first
            assert await q.command(1) == first
        await q.command(1)


@cocotb.test()
async def test_random_multiset(dut):
    q = Queue(dut)
    await q.reset()
    for _ in range(600):
        op = q.rng.choices((0, 1, 2, 3), (45, 35, 15, 5))[0]
        await q.command(op, q.rng.getrandbits(q.pwidth), q.rng.getrandbits(q.dwidth), q.rng.randrange(4))
    while q.items:
        await q.command(1)


@cocotb.test()
async def test_continuous_handshakes(dut):
    q = Queue(dut)
    await q.reset()
    issued = completed = 0
    pending = None
    occupancy = 0
    dut.rsp_ready.value = 1
    for _ in range(600):
        # Inspect pre-edge ready/valid, then drive the next command. Valid
        # stays high across response consumption and the next ready cycle.
        if int(dut.rsp_valid.value):
            assert pending is not None and not int(dut.rsp_error.value)
            assert pending == (int(dut.rsp_priority.value), int(dut.rsp_data.value))
            pending = None
            completed += 1
        dut.req_valid.value = issued < 100
        dut.req_op.value = issued % 2
        priority = ((issued // 2) * 7) & q.pmask
        data = ((issued // 2) * 13) & q.dmask
        dut.req_priority.value = priority
        dut.req_data.value = data
        if issued < 100 and int(dut.req_ready.value):
            assert pending is None
            pending = (0, 0) if issued % 2 == 0 else (priority, data)
            occupancy = 1 if issued % 2 == 0 else 0
            issued += 1
        await q.tick()
        assert int(dut.count.value) == occupancy
        assert int(dut.full.value) == (occupancy == q.depth)
        assert int(dut.empty.value) == (occupancy == 0)
        if completed == 100:
            break
    assert issued == completed == 100 and pending is None


@cocotb.test()
async def test_reset_in_flight(dut):
    q = Queue(dut)
    await q.reset()
    # Interrupt insertion, removal, and an unconsumed response at every
    # possible heap-level offset; reset must suppress stale completions.
    for op in (0, 1, 2):
        for delay in range(q.depth.bit_length() + 2):
            await q.reset()
            for i in range(max(1, q.depth - 1)):
                await q.command(0, i, i)
            dut.req_valid.value = 1
            dut.req_op.value = op
            dut.req_priority.value = 0 if q.min_first else q.pmask
            dut.req_data.value = q.dmask
            dut.rsp_ready.value = 0
            await q.tick()
            dut.req_valid.value = 0
            for _ in range(delay):
                await q.tick()
            await q.reset()
            for _ in range(q.depth.bit_length() + 3):
                await q.tick()
                assert not int(dut.rsp_valid.value)
                q.flags()
            await q.command(0, q.pmask, q.dmask)
            assert await q.command(1) == (q.pmask, q.dmask)
