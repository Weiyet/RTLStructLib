"""Port-only allocation checks using a Python set of owned IDs."""
import os
import random

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def allocation_contract(dut):
    capacity = int(dut.CAPACITY.value)
    id_mask = (1 << len(dut.free_id)) - 1
    owned = set()
    rng = random.Random(int(os.getenv("TB_SEED", "123")))
    limit = int(os.getenv("TB_TIMEOUT_CYCLES", "20000"))
    cycles = 0
    previous = None
    names = ("alloc_valid", "alloc_error", "alloc_id", "free_valid",
             "free_error", "free_count", "exhausted", "all_free")

    def outputs():
        return tuple(int(getattr(dut, name).value) for name in names)

    async def step(allocate=0, release=0, ident=0, reset=0):
        nonlocal cycles, previous
        cycles += 1
        assert cycles <= limit, "Free List watchdog"
        ident &= id_mask
        dut.clk.value = 0
        dut.rst.value = reset
        dut.alloc_req.value = allocate
        dut.free_req.value = release
        dut.free_id.value = ident
        await Timer(5, units="ns")
        if previous is not None:
            assert outputs() == previous, "Outputs changed before the rising edge"
        release_ok = False
        allocate_ok = False
        selected = 0
        if reset:
            owned.clear()
        else:
            release_ok = bool(release and ident in owned)
            if release_ok:
                owned.remove(ident)
            available = set(range(capacity)) - owned
            allocate_ok = bool(allocate and available)
            if allocate_ok:
                selected = min(available)
                owned.add(selected)
        count = capacity - len(owned)
        expected = (int(allocate_ok), int(allocate and not allocate_ok and not reset),
                    selected, int(release_ok), int(release and not release_ok and not reset),
                    count, int(count == 0), int(count == capacity))
        dut.clk.value = 1
        await Timer(5, units="ns")
        assert outputs() == expected, (cycles, allocate, release, ident, expected, outputs())
        previous = expected
        return selected

    await step(1, 1, 0, reset=1)
    await step()
    await step(release=1)
    await step(1, 1, 0)
    await step(release=1)
    for _ in range(3):
        for _ in range(capacity + 1):
            await step(allocate=1)
        ids = list(range(capacity))
        rng.shuffle(ids)
        for ident in ids:
            await step(1, 1, ident)
        for ident in ids:
            await step(release=1, ident=ident)
            await step(release=1, ident=ident)
    for ident in range(capacity, id_mask + 1):
        await step(release=1, ident=ident)
        await step(1, 1, ident)
    # Release a high ID while a lower ID is already available.
    await step(reset=1)
    for _ in range(capacity):
        await step(allocate=1)
    await step(release=1, ident=0)
    await step(1, 1, capacity - 1)
    for cycle in range(2000):
        await step(rng.randrange(2), rng.randrange(2), rng.randrange(id_mask + 1),
                   reset=(cycle % 317 == 316))
    await step(1, 1, 0, reset=1)
    for _ in range(capacity + 1):
        await step(allocate=1)
    for ident in reversed(range(capacity)):
        await step(release=1, ident=ident)
    await step()
    dut._log.info("BITMAP FREE LIST PASSED: %d checked cycles", cycles)
