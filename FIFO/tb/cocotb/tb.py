"""Independent queue scoreboard with unrelated clocks and CDC invariants."""
from collections import deque
import os
import random

import cocotb
from cocotb.triggers import Timer


class Queue:
    def __init__(self, dut):
        self.dut = dut
        self.depth = int(dut.DEPTH.value)
        self.async_mode = int(dut.ASYNC.value)
        self.buffered = int(dut.RD_BUFFER.value)
        self.width = len(dut.data_wr)
        self.wr_half = int(os.getenv("WR_HALF", "3"))
        self.rd_half = int(os.getenv("RD_HALF", "5"))
        self.queue = deque()
        self.output = 0
        self.phase = 0
        self.ticks = 0
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "100000"))
        self.random = random.Random(int(os.getenv("TB_SEED", "123")))
        self.pushes = self.pops = 0

    async def tick(self, write=0, read=0, value=None, stop_wr=False, stop_rd=False):
        self.ticks += 1
        assert self.ticks <= self.limit, "FIFO timed out"
        if value is None:
            value = self.random.getrandbits(self.width)
        self.dut.wr_en.value = write
        self.dut.rd_en.value = read
        self.dut.data_wr.value = value
        await Timer(2, units="ns")
        next_wr = 0 if stop_wr else ((self.phase // self.wr_half) % 2)
        next_rd = 0 if stop_rd else ((self.phase // self.rd_half) % 2)
        if not self.async_mode:
            next_rd = next_wr
        wr_edge = next_wr and not int(self.dut.wr_clk.value)
        rd_edge = next_rd and not int(self.dut.rd_clk.value)
        push = wr_edge and write and not int(self.dut.fifo_full.value)
        pop = rd_edge and read and not int(self.dut.fifo_empty.value)
        if not self.buffered:
            readable = read and not int(self.dut.fifo_empty.value)
            assert not readable or self.queue, "empty queue advertised readable"
            assert int(self.dut.data_rd.value) == (self.queue[0] if readable else 0)
        if pop:
            assert self.queue, "underflow accepted"
            self.output = self.queue.popleft()
            self.pops += 1
        if push:
            assert len(self.queue) < self.depth, "overflow accepted"
            self.queue.append(value)
            self.pushes += 1
        if self.async_mode:
            block = self.dut.async_fifo
            old_gray = [int(block.wr_gray.value), int(block.rd_gray.value)]
        self.dut.wr_clk.value = next_wr
        self.dut.rd_clk.value = next_rd
        self.phase += 1
        await Timer(2, units="ns")
        if self.buffered:
            assert int(self.dut.data_rd.value) == self.output
        if self.async_mode:
            for old, signal in zip(old_gray, (block.wr_gray, block.rd_gray)):
                difference = old ^ int(signal.value)
                assert (difference & (difference - 1)) == 0, "source Gray pointer changed multiple bits"
        elif int(self.dut.wr_ready.value):
            assert int(self.dut.fifo_empty.value) == (not self.queue)
            assert int(self.dut.fifo_full.value) == (len(self.queue) == self.depth)

    async def reset(self, warm=True):
        self.dut.wr_clk.value = 0
        self.dut.rd_clk.value = 0
        self.dut.wr_en.value = 0
        self.dut.rd_en.value = 0
        self.dut.data_wr.value = 0
        self.dut.rst.value = 0
        await Timer(2, units="ns")
        self.dut.rst.value = 1
        self.queue.clear()
        self.output = 0
        self.phase = 0
        await Timer(2, units="ns")
        assert int(self.dut.fifo_empty.value) == 1
        assert int(self.dut.fifo_full.value) == 1  # backpressure during reset/release
        assert int(self.dut.data_rd.value) == 0
        self.dut.rst.value = 0
        if warm:
            for _ in range(8 * (self.wr_half + self.rd_half)):
                await self.tick()
            assert int(self.dut.fifo_full.value) == 0
            assert int(self.dut.fifo_empty.value) == 1

    async def fill(self):
        for _ in range((self.depth + 8) * 2 * self.wr_half):
            await self.tick(write=1)
        assert len(self.queue) == self.depth
        assert int(self.dut.fifo_full.value) == 1

    async def drain(self):
        for _ in range((self.depth + 8) * 2 * self.rd_half):
            await self.tick(read=1)
        assert not self.queue, "drain lost entries"
        assert int(self.dut.fifo_empty.value) == 1


@cocotb.test()
async def test_empty_and_invalid(dut):
    queue = Queue(dut)
    await queue.reset()
    await queue.drain()
    await queue.fill()
    for _ in range(60):
        await queue.tick(write=1)
    await queue.drain()


@cocotb.test()
async def test_full_capacity_and_wrap(dut):
    queue = Queue(dut)
    await queue.reset()
    for _ in range(5):
        await queue.fill()
        await queue.drain()
    assert queue.pushes == queue.pops == 5 * queue.depth


@cocotb.test()
async def test_simultaneous_and_random(dut):
    queue = Queue(dut)
    await queue.reset()
    for _ in range(1800):
        await queue.tick(1, 1)
    for _ in range(4000):
        await queue.tick(queue.random.randrange(2), queue.random.randrange(2))
    await queue.drain()
    assert queue.pushes == queue.pops > 0


@cocotb.test()
async def test_reset_and_stopped_clocks(dut):
    queue = Queue(dut)
    await queue.reset()
    await queue.fill()
    await queue.reset(warm=False)
    for _ in range(30):
        await queue.tick(1, 1, stop_wr=True, stop_rd=True)
    assert not queue.queue
    if queue.async_mode:
        for _ in range((queue.depth + 8) * 2 * queue.wr_half):
            await queue.tick(1, 1, stop_rd=True)
        assert len(queue.queue) == queue.depth
        assert int(dut.fifo_empty.value) == 1
        for _ in range((queue.depth + 8) * 2 * queue.rd_half):
            await queue.tick(0, 1, stop_wr=True)
        assert not queue.queue
    await queue.reset()
    await queue.fill()
    await queue.drain()


@cocotb.test()
async def test_data_bits(dut):
    queue = Queue(dut)
    await queue.reset()
    for bit in range(queue.width):
        value = 1 << bit
        for _ in range(2 * queue.wr_half):
            await queue.tick(write=1, value=value)
        for _ in range(2 * queue.rd_half * 5):
            await queue.tick(read=1)
    await queue.drain()