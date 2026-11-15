"""Dictionary oracle for real Hash Table RTL, including bucket capacity."""
import os
import random

import cocotb
from cocotb.triggers import Timer


class HashTable:
    def __init__(self, dut):
        self.dut = dut
        self.key_width = len(dut.key_in)
        self.value_width = len(dut.value_in)
        self.key_mask = (1 << self.key_width) - 1
        self.value_mask = (1 << self.value_width) - 1
        self.buckets = int(dut.TOTAL_INDEX.value)
        self.chain = int(dut.CHAINING_SIZE.value)
        self.limit = int(os.getenv("TB_TIMEOUT_CYCLES", "100"))
        self.model = {}
        self.random = random.Random(int(os.getenv("TB_SEED", "123")))

    async def clock(self):
        self.dut.clk.value = 0
        await Timer(5, units="ns")
        self.dut.clk.value = 1
        await Timer(5, units="ns")

    async def reset(self):
        self.dut.clk.value = 0
        self.dut.rst.value = 0
        self.dut.op_en.value = 0
        self.dut.op_sel.value = 0
        self.dut.key_in.value = 0
        self.dut.value_in.value = 0
        await Timer(2, units="ns")
        self.dut.rst.value = 1
        self.model.clear()
        await Timer(2, units="ns")
        for signal in (self.dut.op_done, self.dut.op_error, self.dut.value_out, self.dut.collision_count):
            assert int(signal.value) == 0
        self.dut.rst.value = 0
        await self.clock()

    async def operation(self, action, key, value=0):
        key &= self.key_mask
        value &= self.value_mask
        bucket = key % self.buckets
        occupancy = sum(k % self.buckets == bucket for k in self.model)
        error = False
        result = 0
        if action == 0:
            if key in self.model or occupancy < self.chain:
                self.model[key] = value
            else:
                error = True
        elif action == 1:
            if key in self.model:
                del self.model[key]
            else:
                error = True
        elif action == 2:
            error = key not in self.model
            result = self.model.get(key, 0)
        else:
            error = True
        count = sum(k % self.buckets == bucket for k in self.model) if action != 3 else 0
        self.dut.key_in.value = key
        self.dut.value_in.value = value
        self.dut.op_sel.value = action
        self.dut.op_en.value = 1
        await self.clock()  # sample the request
        assert not int(self.dut.op_done.value)
        # Change every request field and inject busy-cycle enable pulses.
        self.dut.key_in.value = key ^ self.key_mask
        self.dut.value_in.value = value ^ self.value_mask
        self.dut.op_sel.value = action ^ 3
        for waited in range(1, min(self.limit, self.chain + 3)):
            self.dut.op_en.value = waited % 2
            await self.clock()
            if int(self.dut.op_done.value):
                break
        else:
            raise AssertionError("Hash Table timed out")
        assert int(self.dut.op_error.value) == error, (action, key, self.model)
        assert int(self.dut.value_out.value) == result, (action, key, result)
        assert int(self.dut.collision_count.value) == count, (action, key, count)
        self.dut.op_en.value = 0
        await self.clock()  # completion pulse clears; next cycle may accept a request
        assert int(self.dut.op_done.value) == int(self.dut.op_error.value) == 0
        assert int(self.dut.value_out.value) == result
        return result

    def colliding_keys(self):
        return [i * self.buckets for i in range(self.chain + 2)
                if i * self.buckets <= self.key_mask]


@cocotb.test()
async def test_empty_and_invalid(dut):
    table = HashTable(dut)
    await table.reset()
    for key in (0, table.key_mask):
        await table.operation(2, key)
        await table.operation(1, key)
        await table.operation(3, key)
    await table.operation(0, 0, table.value_mask)
    await table.operation(2, 0)
    await table.operation(1, 0)
    await table.operation(2, 0)


@cocotb.test()
async def test_full_and_duplicate(dut):
    table = HashTable(dut)
    await table.reset()
    keys = table.colliding_keys()
    for key in keys:
        await table.operation(0, key, key & table.value_mask)
    for _ in range(3):
        for key in keys[:table.chain]:
            await table.operation(0, key, table.random.getrandbits(table.value_width))
    for key in keys:
        await table.operation(2, key)
    if len(keys) > table.chain:
        assert len(table.model) == table.chain
    await table.operation(1, 0)
    await table.operation(0, keys[-1], table.value_mask)
    for key in keys:
        await table.operation(2, key)


@cocotb.test()
async def test_delete_preserves_chain(dut):
    table = HashTable(dut)
    keys = table.colliding_keys()[:table.chain]
    for removed in keys:
        await table.reset()
        for key in keys:
            await table.operation(0, key, table.random.getrandbits(table.value_width))
        await table.operation(1, removed)
        for key in keys:
            await table.operation(2, key)
        await table.operation(1, removed)
        await table.operation(0, removed, 0)
        for key in keys:
            await table.operation(2, key)


@cocotb.test()
async def test_request_latching_and_bits(dut):
    table = HashTable(dut)
    await table.reset()
    for bit in range(table.key_width):
        await table.operation(0, 1 << bit, table.value_mask)
        await table.operation(2, 1 << bit)
        await table.operation(1, 1 << bit)
    for bit in range(table.value_width):
        await table.operation(0, table.key_mask, 1 << bit)
        await table.operation(2, table.key_mask)
    await table.operation(1, table.key_mask)


@cocotb.test()
async def test_reset_during_operation(dut):
    table = HashTable(dut)
    await table.reset()
    for key in table.colliding_keys()[:table.chain]:
        await table.operation(0, key, table.value_mask)
    for action in (0, 1, 2):
        dut.op_sel.value = action
        dut.key_in.value = 0
        dut.op_en.value = 1
        await table.clock()
        await table.reset()
        await table.operation(2, 0)
        await table.operation(0, 0, 0)
        await table.operation(2, 0)


@cocotb.test()
async def test_random_operations(dut):
    table = HashTable(dut)
    await table.reset()
    for cycle in range(700):
        if table.model and table.random.randrange(2):
            key = table.random.choice(list(table.model))
        else:
            key = table.random.getrandbits(table.key_width)
            if cycle % 2 == 0:
                key %= 2 * table.buckets * table.chain
        await table.operation(table.random.randrange(4), key,
                              table.random.getrandbits(table.value_width))
        if cycle % 173 == 0:
            await table.reset()
    for key in list(table.model):
        await table.operation(2, key)