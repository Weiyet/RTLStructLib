"""Port-only register-file model; writes are applied before sampled reads."""
import os
import random

import cocotb
from cocotb.triggers import Timer


class Table:
    def __init__(self, dut):
        self.dut = dut
        self.size = int(dut.TABLE_SIZE.value)
        self.width = int(dut.DATA_WIDTH.value)
        self.inputs = int(dut.INPUT_RATE.value)
        self.outputs = int(dut.OUTPUT_RATE.value)
        self.index_width = max(1, (self.size - 1).bit_length())
        self.memory = [0] * self.size
        self.output = 0
        self.cycles = 0
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "20000"))
        self.random = random.Random(int(os.getenv("TB_SEED", "123")))

    @staticmethod
    def pack(values, width):
        return sum(value << (port * width) for port, value in enumerate(values))

    async def step(self, writes=None, reads=None, enabled=True):
        self.cycles += 1
        assert self.cycles <= self.limit, "Table timed out"
        writes = writes or [(False, 0, 0)] * self.inputs
        reads = reads or [0] * self.outputs
        self.dut.clk.value = 0
        self.dut.wr_en.value = self.pack([int(item[0]) for item in writes], 1)
        self.dut.index_wr.value = self.pack([item[1] for item in writes], self.index_width)
        self.dut.data_wr.value = self.pack([item[2] for item in writes], self.width)
        self.dut.index_rd.value = self.pack(reads, self.index_width)
        self.dut.rd_en.value = enabled
        await Timer(4, units="ns")
        assert int(self.dut.data_rd.value) == self.output, "output changed before edge"
        for enable, address, value in writes:
            if enable and address < self.size:
                self.memory[address] = value
        if enabled:
            self.output = self.pack([self.memory[a] if a < self.size else 0 for a in reads], self.width)
        self.dut.clk.value = 1
        await Timer(4, units="ns")
        assert int(self.dut.data_rd.value) == self.output

    async def reset(self):
        self.dut.clk.value = 0
        self.dut.rst.value = 0
        self.dut.wr_en.value = 0
        self.dut.rd_en.value = 0
        self.dut.index_wr.value = 0
        self.dut.index_rd.value = 0
        self.dut.data_wr.value = 0
        await Timer(2, units="ns")
        self.dut.rst.value = 1
        self.memory = [0] * self.size
        self.output = 0
        await Timer(2, units="ns")
        assert int(self.dut.data_rd.value) == 0
        self.dut.rst.value = 0
        await self.step()


@cocotb.test()
async def test_empty_and_invalid(dut):
    table = Table(dut)
    await table.reset()
    for address in range(1 << table.index_width):
        await table.step(reads=[address] * table.outputs)
        if address >= table.size:
            await table.step([(True, address, (1 << table.width) - 1)] * table.inputs,
                             [address] * table.outputs)
    for address in range(table.size):
        await table.step(reads=[address] * table.outputs)


@cocotb.test()
async def test_write_priority_and_forwarding(dut):
    table = Table(dut)
    await table.reset()
    mask = (1 << table.width) - 1
    for address in range(table.size):
        for highest in range(table.inputs):
            writes = [(port <= highest, address, (port + address + 1) & mask)
                      for port in range(table.inputs)]
            await table.step(writes, [address] * table.outputs)
            await table.step(reads=[address] * table.outputs)


@cocotb.test()
async def test_independent_ports_and_bits(dut):
    table = Table(dut)
    await table.reset()
    for bit in range(table.width):
        for base in range(table.size):
            writes = [(True, (base + port) % table.size, 1 << bit) for port in range(table.inputs)]
            reads = [(base + port) % table.size for port in range(table.outputs)]
            await table.step(writes, reads)
            await table.step(reads=reads)


@cocotb.test()
async def test_read_hold_and_reset(dut):
    table = Table(dut)
    await table.reset()
    await table.step([(True, 0, (1 << table.width) - 1)] * table.inputs)
    await table.step([(True, 0, 0)] * table.inputs, enabled=False)
    await table.step(enabled=False)
    await table.reset()
    for address in range(table.size):
        await table.step(reads=[address] * table.outputs)


@cocotb.test()
async def test_random_ports(dut):
    table = Table(dut)
    await table.reset()
    for cycle in range(1500):
        writes = [(bool(table.random.randrange(2)), table.random.randrange(1 << table.index_width),
                   table.random.getrandbits(table.width)) for _ in range(table.inputs)]
        reads = [table.random.randrange(1 << table.index_width) for _ in range(table.outputs)]
        await table.step(writes, reads, bool(table.random.randrange(2)))
        if cycle % 251 == 0:
            await table.reset()