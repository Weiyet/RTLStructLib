"""Shared black-box checks for the two NULL-terminated hardware linked lists."""

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge


READ, INSERT_ADDR, DELETE_VALUE, DELETE_ADDR = range(4)
INSERT_INDEX, DELETE_INDEX = 5, 7


class LinkedListBench:
    def __init__(self, dut):
        self.dut = dut
        self.capacity = int(dut.MAX_NODE.value)
        self.data_mask = (1 << int(dut.DATA_WIDTH.value)) - 1
        self.addr_mask = (1 << len(dut.addr_in)) - 1
        self.bidirectional = hasattr(dut, "pre_node_addr")
        self.limit = min(self.capacity + 4, int(os.getenv("TB_TIMEOUT_CYCLES", "1000")))
        self.random = random.Random(int(os.getenv("TB_SEED", "1")))
        self.nodes = []
        self.last_read = None
        self.last_cycles = 0

    async def initialize(self):
        self.dut.op_start.value = 0
        self.dut.op.value = 0
        self.dut.addr_in.value = 0
        self.dut.data_in.value = 0
        cocotb.start_soon(Clock(self.dut.clk, 10, units="ns").start())
        await self.reset()

    def status(self):
        assert int(self.dut.length.value) == len(self.nodes)
        assert int(self.dut.empty.value) == (not self.nodes)
        assert int(self.dut.full.value) == (len(self.nodes) == self.capacity)
        assert int(self.dut.head.value) == (self.nodes[0][0] if self.nodes else self.capacity)
        assert int(self.dut.tail.value) == (self.nodes[-1][0] if self.nodes else self.capacity)

    def read_outputs(self):
        previous = int(self.dut.pre_node_addr.value) if self.bidirectional else self.capacity
        return int(self.dut.data_out.value), previous, int(self.dut.next_node_addr.value)

    async def reset(self):
        await FallingEdge(self.dut.clk)
        self.dut.rst.value = 1
        self.dut.op_start.value = 0
        for _ in range(2):
            await RisingEdge(self.dut.clk)
        await FallingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await ReadOnly()
        self.nodes = []
        self.last_read = None
        self.status()
        assert not self.dut.op_done.value and not self.dut.fault.value
        assert int(self.dut.data_out.value) == 0
        await FallingEdge(self.dut.clk)

    async def transfer(self, operation, address=0, value=0, disturb=False, hold=False):
        assert not self.dut.op_done.value
        await FallingEdge(self.dut.clk)
        self.dut.op.value = operation
        self.dut.addr_in.value = address & self.addr_mask
        self.dut.data_in.value = value & self.data_mask
        self.dut.op_start.value = 1
        for cycle in range(self.limit):
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            if self.dut.op_done.value:
                self.last_cycles = cycle + 1
                result = int(self.dut.fault.value), *self.read_outputs()
                break
            assert not self.dut.fault.value
            self.status()  # No partial structural updates before completion.
            await FallingEdge(self.dut.clk)
            self.dut.op_start.value = int(hold or disturb)
            if not hold:
                self.dut.op.value = INSERT_INDEX
                self.dut.addr_in.value = 0
                self.dut.data_in.value = (value ^ self.data_mask) & self.data_mask
        else:
            raise AssertionError(f"Operation {operation} timed out after {self.limit} cycles")
        await FallingEdge(self.dut.clk)
        self.dut.op_start.value = 0
        await RisingEdge(self.dut.clk)
        await ReadOnly()
        assert not self.dut.op_done.value and not self.dut.fault.value
        await FallingEdge(self.dut.clk)
        return result

    async def command(self, operation, address=0, value=0, disturb=False, hold=False):
        address &= self.addr_mask
        value &= self.data_mask
        expected = list(self.nodes)
        indices = [i for i, (node_address, _) in enumerate(expected) if node_address == address]
        fault = False
        read_data, previous, following = 0, self.capacity, self.capacity
        indexed_bound = None
        if operation == READ:
            fault = not indices
            if not fault:
                index = indices[0]
                read_data = expected[index][1]
                previous = expected[index-1][0] if index else self.capacity
                following = expected[index+1][0] if index+1 < len(expected) else self.capacity
        elif operation in (INSERT_ADDR, INSERT_INDEX):
            fault = len(expected) == self.capacity
            if operation == INSERT_INDEX:
                index = min(address, len(expected))
                if address < len(expected):
                    indexed_bound = min(address, len(expected)-1-address) + 4
            elif address >= self.capacity:
                index = len(expected)
            elif indices:
                index = indices[0]
            else:
                fault = True
            if not fault:
                occupied = {node_address for node_address, _ in expected}
                allocated = next(node_address for node_address in range(self.capacity)
                                 if node_address not in occupied)
                expected.insert(index, (allocated, value))
        elif operation in (DELETE_VALUE, DELETE_ADDR, DELETE_INDEX):
            if operation == DELETE_VALUE:
                indices = [i for i, (_, node_value) in enumerate(expected) if node_value == value]
            elif operation == DELETE_INDEX:
                indices = [address] if address < len(expected) else []
                if indices:
                    indexed_bound = min(address, len(expected)-1-address) + 4
            fault = not indices
            if not fault:
                del expected[indices[0]]
        else:
            fault = True
        actual = await self.transfer(operation, address, value, disturb, hold)
        assert actual[0] == fault, f"Operation {operation}: fault {actual[0]}, expected {fault}"
        if operation == READ and not fault:
            # SLL has no previous-pointer hardware.
            previous = previous if self.bidirectional else self.capacity
            assert actual[1:] == (read_data, previous, following), (
                f"Read {address}: got {actual[1:]}, expected {(read_data, previous, following)}")
            self.last_read = actual[1:]
        elif self.last_read is not None:
            assert actual[1:] == self.last_read, "Non-read/failed operation changed held read outputs"
        if not fault and self.bidirectional and indexed_bound is not None:
            assert self.last_cycles <= indexed_bound, "DLL did not walk from the nearer endpoint"
        self.nodes = expected
        self.status()
        return actual

    async def check_list(self):
        self.status()
        for address in range(self.capacity + 1):
            await self.command(READ, address)
        if self.addr_mask > self.capacity:
            await self.command(READ, self.addr_mask)

    async def fill(self, value=None):
        for index in range(self.capacity):
            await self.command(INSERT_INDEX, self.capacity,
                               index & self.data_mask if value is None else value)


async def setup(dut):
    bench = LinkedListBench(dut)
    await bench.initialize()
    return bench


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_empty_and_invalid(dut):
    bench = await setup(dut)
    for operation in (READ, DELETE_VALUE, DELETE_ADDR, DELETE_INDEX, 4, 6, INSERT_ADDR):
        await bench.command(operation, 0)
    await bench.command(READ, bench.capacity)
    await bench.command(INSERT_ADDR, bench.capacity, bench.data_mask)
    await bench.check_list()
    for operation in (READ, DELETE_ADDR, DELETE_INDEX, 4, 6):
        await bench.command(operation, bench.addr_mask)
    await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_singleton_endpoints(dut):
    bench = await setup(dut)
    for operation in (DELETE_INDEX, DELETE_ADDR, DELETE_VALUE):
        await bench.command(INSERT_INDEX, 0, bench.data_mask)
        assert bench.nodes[0][0] == 0
        await bench.check_list()
        for _ in range(3):
            _, _, previous, following = await bench.command(READ, 0)
            assert previous == following == bench.capacity
        await bench.command(operation, 0, bench.data_mask)
        await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_insert_positions_and_full(dut):
    bench = await setup(dut)
    for trial in range(bench.capacity):
        if trial % 4 == 0:
            await bench.command(INSERT_INDEX, bench.addr_mask, trial)
        elif trial % 4 == 1:
            await bench.command(INSERT_ADDR, bench.nodes[0][0], trial)
        elif trial % 4 == 2:
            await bench.command(INSERT_INDEX, len(bench.nodes) // 2, trial)
        else:
            await bench.command(INSERT_ADDR, bench.nodes[-1][0], trial)
        await bench.check_list()
    for operation, address in ((INSERT_ADDR, bench.capacity), (INSERT_ADDR, bench.nodes[0][0]),
                               (INSERT_INDEX, 0), (INSERT_INDEX, bench.addr_mask)):
        await bench.command(operation, address, 7)
        await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_delete_positions_and_duplicates(dut):
    bench = await setup(dut)
    await bench.fill(0)
    await bench.command(DELETE_VALUE, value=bench.data_mask)  # Missing value: one bounded forward pass.
    await bench.check_list()
    for trial in range(bench.capacity):
        if trial % 4 == 0:
            await bench.command(DELETE_VALUE, value=0)  # Delete the first duplicate.
        elif trial % 4 == 1:
            await bench.command(DELETE_ADDR, bench.nodes[-1][0])
        elif trial % 4 == 2:
            await bench.command(DELETE_INDEX, len(bench.nodes) // 2)
        else:
            await bench.command(DELETE_ADDR, bench.nodes[0][0])
        await bench.check_list()
    await bench.command(DELETE_VALUE, value=0)
    await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_address_reuse(dut):
    bench = await setup(dut)
    await bench.fill()
    for trial in range(bench.capacity + 2):
        removed = bench.nodes[len(bench.nodes) // 2][0]
        await bench.command(DELETE_ADDR, removed)
        await bench.command(READ, removed)
        await bench.command(INSERT_ADDR, removed, 1)  # Vacant storage is not an insertion target.
        await bench.command(INSERT_INDEX, 0, trial)
        assert bench.nodes[0][0] == removed
        await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_traversal_and_latched_requests(dut):
    bench = await setup(dut)
    for index in range(bench.capacity):
        await bench.command(INSERT_INDEX, bench.capacity, index, disturb=True)
    await bench.check_list()
    for reverse in ((False, True) if bench.bidirectional else (False,)):
        expected_nodes = list(reversed(bench.nodes)) if reverse else bench.nodes
        for _ in range(2):
            address = expected_nodes[0][0]
            for expected_address, expected_value in expected_nodes:
                assert address == expected_address
                _, value, previous, following = await bench.command(READ, address, disturb=True)
                assert value == expected_value
                address = previous if reverse else following
            assert address == bench.capacity, "Traversal must terminate at NULL"
    # Near-tail indexed operations also enforce the DLL traversal latency bound.
    await bench.command(DELETE_INDEX, len(bench.nodes)-1, disturb=True)
    await bench.command(INSERT_INDEX, 0, bench.data_mask, disturb=True)
    await bench.command(DELETE_VALUE, value=bench.data_mask, disturb=True)
    await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_random_operations(dut):
    bench = await setup(dut)
    for _ in range(200):
        operation = bench.random.choice([INSERT_ADDR, INSERT_INDEX, INSERT_INDEX, READ,
                                         DELETE_ADDR, DELETE_INDEX, DELETE_VALUE, 4, 6])
        address = bench.random.randrange(bench.addr_mask + 1)
        value = bench.random.randrange(bench.data_mask + 1)
        if bench.nodes and bench.random.randrange(2):
            address, existing_value = bench.random.choice(bench.nodes)
            if operation == DELETE_VALUE:
                value = existing_value
        await bench.command(operation, address, value, disturb=True)
        await bench.check_list()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_reset_during_operations(dut):
    bench = await setup(dut)
    for operation in (INSERT_INDEX, DELETE_INDEX, DELETE_VALUE):
        if operation != INSERT_INDEX:
            await bench.fill(0)
        await FallingEdge(dut.clk)
        dut.op.value = operation
        dut.addr_in.value = bench.capacity - 1
        dut.data_in.value = bench.data_mask
        dut.op_start.value = 1
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert not dut.op_done.value
        if operation == DELETE_VALUE:
            for _ in range(bench.capacity):
                await FallingEdge(dut.clk)
                dut.op_start.value = 0
                await RisingEdge(dut.clk)
                await ReadOnly()
                assert not dut.op_done.value
        await bench.reset()
        assert int(dut.next_node_addr.value) == bench.capacity
        if bench.bidirectional:
            assert int(dut.pre_node_addr.value) == bench.capacity
        for _ in range(bench.capacity + 5):
            await RisingEdge(dut.clk)
            await ReadOnly()
            assert not dut.op_done.value and not dut.fault.value
        await bench.check_list()
        await bench.command(INSERT_INDEX, 0, 1)
        await bench.command(DELETE_INDEX, 0)
        await bench.reset()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_read_output_hold(dut):
    bench = await setup(dut)
    await bench.command(INSERT_INDEX, 0, bench.data_mask)
    await bench.command(READ, 0)
    await bench.command(DELETE_INDEX, 0)
    await bench.command(READ, 0)  # Invalid reads must not replace the held output.
    await bench.command(INSERT_INDEX, 0, 0)
    await bench.command(4)
    await bench.command(READ, 0)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_held_start_compatibility(dut):
    bench = await setup(dut)
    for index in range(bench.capacity):
        await bench.command(INSERT_INDEX, bench.capacity, index, hold=True)
    await bench.command(DELETE_VALUE, value=bench.nodes[-1][1], hold=True)
    for _ in range(bench.capacity + 3):
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert not dut.op_done.value and not dut.fault.value
        bench.status()
    await bench.check_list()
