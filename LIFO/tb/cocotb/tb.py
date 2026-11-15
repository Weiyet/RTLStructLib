"""Cycle-accurate port-only checks against a Python stack."""
import os
import random

import cocotb
from cocotb.triggers import Timer


class Stack:
    def __init__(self, dut):
        self.dut = dut
        self.depth = int(dut.DEPTH.value)
        self.width = len(dut.data_wr)
        self.mask = (1 << self.width) - 1
        self.items = []
        self.output = 0
        self.cycles = 0
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "20000"))
        self.random = random.Random(int(os.getenv("TB_SEED", "123")))

    def check(self):
        assert int(self.dut.lifo_empty.value) == (not self.items), self.items
        assert int(self.dut.lifo_full.value) == (len(self.items) == self.depth), self.items
        assert int(self.dut.data_rd.value) == self.output, (
            self.cycles, self.output, int(self.dut.data_rd.value))

    async def step(self, push=0, pop=0, value=0):
        self.cycles += 1
        assert self.cycles <= self.limit, "LIFO timed out"
        value &= self.mask
        self.dut.clk.value = 0
        self.dut.wr_en.value = push
        self.dut.rd_en.value = pop
        self.dut.data_wr.value = value
        await Timer(5, units="ns")
        self.check()  # registered output must not change before the active edge
        if push and pop:
            self.output = value
        elif push and len(self.items) < self.depth:
            self.items.append(value)
        elif pop and self.items:
            self.output = self.items.pop()
        self.dut.clk.value = 1
        await Timer(5, units="ns")
        self.check()

    async def reset(self):
        self.dut.clk.value = 0
        self.dut.rst.value = 0
        self.dut.wr_en.value = 1
        self.dut.rd_en.value = 1
        self.dut.data_wr.value = self.mask
        await Timer(2, units="ns")
        self.dut.rst.value = 1
        self.items.clear()
        self.output = 0
        await Timer(2, units="ns")
        self.check()  # asynchronous reset with the clock stopped
        self.dut.clk.value = 1
        await Timer(5, units="ns")
        self.check()
        self.dut.clk.value = 0
        self.dut.rst.value = 0
        await self.step()


@cocotb.test()
async def test_empty_and_invalid(dut):
    stack = Stack(dut)
    await stack.reset()
    for _ in range(5):
        await stack.step(pop=1)
        await stack.step()
    await stack.step(1, 1, stack.mask)
    await stack.step(pop=1)


@cocotb.test()
async def test_full_drain_and_wrap(dut):
    stack = Stack(dut)
    await stack.reset()
    for _ in range(5):
        for _ in range(stack.depth):
            await stack.step(push=1, value=stack.random.getrandbits(stack.width))
        for _ in range(3):
            await stack.step(push=1, value=stack.mask)
        for _ in range(stack.depth + 2):
            await stack.step(pop=1)


@cocotb.test()
async def test_bypass_at_every_occupancy(dut):
    stack = Stack(dut)
    await stack.reset()
    for occupancy in range(stack.depth + 1):
        for value in (0, stack.mask, stack.random.getrandbits(stack.width)):
            await stack.step(1, 1, value)
            await stack.step()
        if occupancy < stack.depth:
            await stack.step(push=1, value=occupancy)
    for _ in range(stack.depth):
        await stack.step(pop=1)


@cocotb.test()
async def test_reset_discards_entries(dut):
    stack = Stack(dut)
    await stack.reset()
    for occupancy in (1, stack.depth // 2, stack.depth):
        for _ in range(occupancy):
            await stack.step(push=1, value=stack.mask)
        await stack.reset()
        await stack.step(pop=1)
        await stack.step(push=1, value=0)
        await stack.step(pop=1)


@cocotb.test()
async def test_all_data_bits(dut):
    stack = Stack(dut)
    await stack.reset()
    for bit in range(stack.width):
        await stack.step(push=1, value=1 << bit)
        await stack.step(pop=1)
        await stack.step(1, 1, stack.mask ^ (1 << bit))


@cocotb.test()
async def test_random_operations(dut):
    stack = Stack(dut)
    await stack.reset()
    for cycle in range(1500):
        await stack.step(stack.random.randrange(2), stack.random.randrange(2),
                         stack.random.getrandbits(stack.width))
        if cycle % 211 == 0:
            await stack.reset()
    while stack.items:
        await stack.step(pop=1)