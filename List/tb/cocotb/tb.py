"""Bounded, model-based checks of the actual List transaction interface."""

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge


READ, INSERT, FIND_ALL, FIND_FIRST, SUM, ASCENDING, DESCENDING, DELETE = range(8)


class ListBench:
    def __init__(self, dut):
        self.dut = dut
        self.capacity = int(dut.LENGTH.value)
        self.mask = (1 << int(dut.DATA_WIDTH.value)) - 1
        self.index_mask = (1 << len(dut.index_in)) - 1
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "1000"))
        self.random = random.Random(int(os.getenv("TB_SEED", "1")))
        self.values = []

    async def initialize(self):
        cocotb.start_soon(Clock(self.dut.clk, 10, units="ns").start())
        self.dut.op_en.value = 0
        self.dut.op_sel.value = 0
        self.dut.data_in.value = 0
        self.dut.index_in.value = 0
        await self.reset()

    async def reset(self):
        await FallingEdge(self.dut.clk)
        self.dut.op_en.value = 0
        self.dut.rst.value = 1
        for _ in range(2):
            await RisingEdge(self.dut.clk)
        await FallingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await ReadOnly()
        assert int(self.dut.len.value) == 0
        assert not self.dut.op_done.value and not self.dut.op_in_progress.value
        assert not self.dut.op_error.value
        self.values = []
        await FallingEdge(self.dut.clk)

    async def request(self, operation, index=0, value=0, disturb=False):
        assert not self.dut.op_done.value and not self.dut.op_in_progress.value
        await FallingEdge(self.dut.clk)
        self.dut.op_sel.value = operation
        self.dut.index_in.value = index & self.index_mask
        self.dut.data_in.value = value & self.mask
        self.dut.op_en.value = 1
        matches = []
        for cycle in range(self.limit):
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            done = int(self.dut.op_done.value)
            busy = int(self.dut.op_in_progress.value)
            error = int(self.dut.op_error.value)
            data = int(self.dut.data_out.value)
            if done and busy:
                assert operation == FIND_ALL, "Unexpected intermediate completion"
                assert not error, "Search match reported an error"
                matches.append(data)
            if done and not busy:
                result = data, error, matches
                break
            await FallingEdge(self.dut.clk)
            # Busy operations must latch the one-cycle command and ignore new requests.
            self.dut.op_en.value = int(disturb and busy)
            self.dut.op_sel.value = INSERT
            self.dut.index_in.value = self.index_mask
            self.dut.data_in.value = (value ^ self.mask) & self.mask
        else:
            raise AssertionError(f"Operation {operation} timed out after {self.limit} cycles")
        await FallingEdge(self.dut.clk)
        self.dut.op_en.value = 0
        await RisingEdge(self.dut.clk)
        await ReadOnly()
        assert not self.dut.op_done.value, "Completion must clear on the next clock"
        assert not self.dut.op_in_progress.value
        await FallingEdge(self.dut.clk)
        return result

    async def insert(self, index, value):
        _, error, _ = await self.request(INSERT, index, value)
        full = len(self.values) == self.capacity
        assert error == full
        if not full:
            self.values.insert(min(index & self.index_mask, len(self.values)), value & self.mask)
        assert int(self.dut.len.value) == len(self.values)

    async def delete(self, index):
        _, error, _ = await self.request(DELETE, index)
        index &= self.index_mask
        assert error == (index >= len(self.values))
        if not error:
            del self.values[index]
        assert int(self.dut.len.value) == len(self.values)

    async def read(self, index):
        value, error, _ = await self.request(READ, index)
        index &= self.index_mask
        assert error == (index >= len(self.values))
        if not error:
            assert value == self.values[index], f"Index {index}: got {value}, expected {self.values[index]}"

    async def check_contents(self):
        assert int(self.dut.len.value) == len(self.values)
        for index in range(len(self.values)):
            await self.read(index)

    async def sum(self, disturb=False):
        value, error, _ = await self.request(SUM, disturb=disturb)
        assert not error
        assert value == sum(self.values), f"Sum: got {value}, expected {sum(self.values)}"

    async def sort(self, descending=False, disturb=False):
        _, error, _ = await self.request(DESCENDING if descending else ASCENDING, disturb=disturb)
        assert not error
        self.values.sort(reverse=descending)
        await self.check_contents()

    async def find(self, value, all_matches=False, disturb=False):
        expected = [i for i, item in enumerate(self.values) if item == (value & self.mask)]
        data, error, matches = await self.request(FIND_ALL if all_matches else FIND_FIRST,
                                                  value=value, disturb=disturb)
        assert error == (not expected), f"Search error: got {error}, matches {expected}"
        if all_matches:
            assert matches == expected, f"Search indices: got {matches}, expected {expected}"
        elif expected:
            assert data == expected[0]


async def setup(dut):
    bench = ListBench(dut)
    await bench.initialize()
    return bench


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_empty_operations(dut):
    bench = await setup(dut)
    await bench.read(0)
    await bench.delete(0)
    for value in (0, bench.mask):
        await bench.find(value)
        await bench.find(value, all_matches=True)
    await bench.sum()
    await bench.sort()
    await bench.sort(descending=True)
    await bench.insert(0, bench.mask)
    await bench.sum()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_insert_delete_boundaries(dut):
    bench = await setup(dut)
    for index in range(bench.capacity):
        await bench.insert(0 if index % 2 else bench.index_mask, index + 1)
        await bench.check_contents()
    await bench.insert(0, 7)
    await bench.check_contents()
    for _ in range(bench.capacity):
        await bench.delete(len(bench.values) // 2)
        await bench.check_contents()
        await bench.sum()
    await bench.delete(0)
    await bench.read(0)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_search_results(dut):
    bench = await setup(dut)
    for index in range(bench.capacity):
        await bench.insert(index, 0 if index % 2 else bench.mask)
    for value in (0, bench.mask):
        await bench.find(value, disturb=True)
        await bench.find(value, all_matches=True, disturb=True)
    await bench.check_contents()
    await bench.reset()
    for index in range(bench.capacity):
        await bench.insert(index, 0)
    await bench.find(bench.mask)
    await bench.find(bench.mask, all_matches=True)
    await bench.find(0, all_matches=True)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_repeated_sum_and_maximum(dut):
    bench = await setup(dut)
    for index in range(bench.capacity):
        await bench.insert(index, bench.mask)
    for _ in range(3):
        await bench.sum(disturb=True)
    await bench.delete(0)
    await bench.sum()
    await bench.insert(0, 1)
    await bench.sum()
    await bench.check_contents()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_sort_patterns(dut):
    bench = await setup(dut)
    patterns = [list(range(bench.capacity)), list(reversed(range(bench.capacity))),
                [bench.mask if index % 2 else 0 for index in range(bench.capacity)],
                [bench.mask] * bench.capacity]
    for pattern in patterns:
        await bench.reset()
        for index, value in enumerate(pattern):
            await bench.insert(index, value)
        await bench.sort(disturb=True)
        await bench.sort(descending=True, disturb=True)
        await bench.sort()
        await bench.sum()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_random_operations(dut):
    bench = await setup(dut)
    for _ in range(120):
        operation = bench.random.randrange(8)
        index = bench.random.randrange(bench.index_mask + 1)
        value = bench.random.randrange(bench.mask + 1)
        if operation == INSERT:
            await bench.insert(index, value)
        elif operation == DELETE:
            await bench.delete(index)
        elif operation == READ:
            await bench.read(index)
        elif operation == SUM:
            await bench.sum()
        elif operation in (ASCENDING, DESCENDING):
            await bench.sort(operation == DESCENDING)
        else:
            await bench.find(value, operation == FIND_ALL)
    await bench.check_contents()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_reset_during_operations(dut):
    bench = await setup(dut)
    for operation in (SUM, ASCENDING, FIND_ALL):
        for index in range(bench.capacity):
            await bench.insert(index, bench.mask - (index % 2))
        await FallingEdge(dut.clk)
        dut.op_sel.value = operation
        dut.data_in.value = bench.mask
        dut.op_en.value = 1
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        dut.op_en.value = 0
        await bench.reset()
        for _ in range(bench.capacity + 3):
            await RisingEdge(dut.clk)
            await ReadOnly()
            assert not dut.op_done.value and not dut.op_in_progress.value
        await bench.insert(0, 1)
        await bench.sum()
        await bench.read(0)
        await bench.reset()
