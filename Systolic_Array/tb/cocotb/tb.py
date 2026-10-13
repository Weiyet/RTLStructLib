"""Check matrix transactions, including stalls and reset recovery."""

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge


class MatrixBench:
    def __init__(self, dut):
        self.dut = dut
        for name in ("ARRAY_ROWS", "ARRAY_COLS", "K_DIM", "DATA_WIDTH",
                     "WEIGHT_WIDTH", "ACC_WIDTH", "SIGNED_MATH", "INPUT_SKEW"):
            setattr(self, name.lower(), int(getattr(dut, name).value))
        assert min(self.array_rows, self.array_cols, self.k_dim,
                   self.data_width, self.weight_width) > 0
        assert self.acc_width >= self.data_width + self.weight_width
        assert self.input_skew in (0, 1)
        assert self.signed_math in (0, 1)
        self.seed = int(os.getenv("TB_SEED", "1"))
        self.rng = random.Random(self.seed)
        self.timeout = int(os.getenv("TB_TIMEOUT_CYCLES", "1000"))
        assert self.timeout > 0
        dut._log.info("TB seed=%d, M=%d, N=%d, K=%d, signed=%d",
                      self.seed, self.array_rows, self.array_cols,
                      self.k_dim, self.signed_math)

    @staticmethod
    def pack(values, width):
        mask = (1 << width) - 1
        return sum((value & mask) << (lane * width)
                   for lane, value in enumerate(values))

    def decode(self, value, width):
        value &= (1 << width) - 1
        if self.signed_math and value & (1 << (width - 1)):
            value -= 1 << width
        return value

    def expected(self, matrix_a, matrix_b):
        """Use integer arithmetic, then wrap to ACC_WIDTH bits."""
        return [[self.decode(sum(
            self.decode(matrix_a[row][k], self.data_width)
            * self.decode(matrix_b[k][col], self.weight_width)
            for k in range(self.k_dim)), self.acc_width)
            for col in range(self.array_cols)] for row in range(self.array_rows)]

    def matrices(self, kind="random"):
        a = [[self.rng.getrandbits(self.data_width) for _ in range(self.k_dim)]
             for _ in range(self.array_rows)]
        b = [[self.rng.getrandbits(self.weight_width) for _ in range(self.array_cols)]
             for _ in range(self.k_dim)]
        if kind == "simple":
            a = [[row * self.k_dim + k + 1 for k in range(self.k_dim)]
                 for row in range(self.array_rows)]
            b = [[k * self.array_cols + col + 1 for col in range(self.array_cols)]
                 for k in range(self.k_dim)]
        elif kind == "identity":
            b = [[int(k == col) for col in range(self.array_cols)]
                 for k in range(self.k_dim)]
        elif kind == "zero":
            a = [[0] * self.k_dim for _ in range(self.array_rows)]
        elif kind == "signed":
            a = [[(-1 if (row + k) % 2 else 1) * (k + 1)
                  for k in range(self.k_dim)] for row in range(self.array_rows)]
            b = [[(-1 if (k + col) % 2 else 1) * (col + 1)
                  for col in range(self.array_cols)] for k in range(self.k_dim)]
        elif kind == "limits":
            def limits(width):
                if self.signed_math:
                    return [-(1 << (width - 1)), (1 << (width - 1)) - 1, -1, 0]
                return [(1 << width) - 1, 1, 0, (1 << width) - 2]
            av, bv = limits(self.data_width), limits(self.weight_width)
            a = [[av[(row + k) % 4] for k in range(self.k_dim)]
                 for row in range(self.array_rows)]
            b = [[bv[(k + col) % 4] for col in range(self.array_cols)]
                 for k in range(self.k_dim)]
        elif kind == "overflow":
            av = -(1 << (self.data_width - 1)) if self.signed_math else (1 << self.data_width) - 1
            bv = -(1 << (self.weight_width - 1)) if self.signed_math else (1 << self.weight_width) - 1
            a = [[av] * self.k_dim for _ in range(self.array_rows)]
            b = [[bv] * self.array_cols for _ in range(self.k_dim)]
        return a, b

    async def reset(self):
        dut = self.dut
        await FallingEdge(dut.clk)
        dut.rst_n.value = 0
        for name in ("start", "weight_valid", "act_valid", "result_ready",
                     "weight_data", "act_data"):
            getattr(dut, name).value = 0
        for _ in range(3):
            await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        for name in ("busy", "done", "result_valid", "weight_ready", "act_ready"):
            assert int(getattr(dut, name).value) == 0, f"{name} active during reset"
        dut.rst_n.value = 1
        for _ in range(2):
            await FallingEdge(dut.clk)
            assert int(dut.busy.value) == 0 and int(dut.done.value) == 0
            assert int(dut.result_valid.value) == 0, "Stale result after reset"

    async def start(self):
        dut = self.dut
        assert int(dut.busy.value) == 0, "DUT busy before start"
        await FallingEdge(dut.clk)
        dut.start.value = 1
        await FallingEdge(dut.clk)
        dut.start.value = 0

    async def send(self, port, value, gaps=False):
        """Drive on falling edges; sample acceptance before rising-edge updates."""
        dut = self.dut
        valid = getattr(dut, f"{port}_valid")
        data = getattr(dut, f"{port}_data")
        ready = getattr(dut, f"{port}_ready")
        if gaps:
            for _ in range(self.rng.randrange(1, 4)):
                await FallingEdge(dut.clk)
                valid.value = 0
                data.value = self.rng.getrandbits(len(data))
                await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        valid.value = 1
        data.value = value
        for _ in range(self.timeout):
            await RisingEdge(dut.clk)
            if int(ready.value):
                return
        raise AssertionError(f"Timed out waiting for {port}_ready")

    async def finish_port(self, port):
        await FallingEdge(self.dut.clk)
        getattr(self.dut, f"{port}_valid").value = 0
        getattr(self.dut, f"{port}_data").value = 0

    async def load_weights(self, matrix_b, gaps=False):
        # Preserve the existing top's K * ARRAY_ROWS loading schedule.
        for row in matrix_b:
            for _ in range(self.array_rows):
                await self.send("weight", self.pack(row, self.weight_width), gaps)
        await self.finish_port("weight")

    def activation_word(self, matrix_a, beat):
        values = []
        for row in range(self.array_rows):
            k = beat if self.input_skew else beat - row
            values.append(matrix_a[row][k] if 0 <= k < self.k_dim else 0)
        return self.pack(values, self.data_width)

    async def stream_activations(self, matrix_a, gaps=False):
        beats = self.k_dim + (0 if self.input_skew else self.array_rows - 1)
        for beat in range(beats):
            await self.send("act", self.activation_word(matrix_a, beat), gaps)
        await self.finish_port("act")

    async def collect(self, expected, backpressure=False):
        dut = self.dut
        count = 0
        held = None
        first_seen = False
        initial_stall = 0
        for cycle in range(self.timeout):
            await FallingEdge(dut.clk)
            if backpressure and (not first_seen or initial_stall < 3):
                ready = 0
                if first_seen:
                    initial_stall += 1
            else:
                ready = int(not backpressure or cycle % 5 not in (0, 1))
            dut.result_ready.value = ready
            await RisingEdge(dut.clk)
            valid = int(dut.result_valid.value)
            data = int(dut.result_data.value) if valid else None
            if held is not None:
                assert valid and data == held, "Stalled result changed or valid dropped"
            held = data if valid and not ready else None
            first_seen |= bool(valid)
            if valid and ready:
                assert count < self.array_rows, "Extra result row"
                actual = [self.decode(data >> (col * self.acc_width), self.acc_width)
                          for col in range(self.array_cols)]
                assert actual == expected[count], (
                    f"C[{count}] mismatch: expected {expected[count]}, got {actual}")
                count += 1
            if int(dut.done.value):
                assert count == self.array_rows, (
                    f"Expected {self.array_rows} result rows, received {count}")
                assert held is None, "done asserted with an unaccepted result"
                assert int(dut.busy.value) == 0, "busy active at done"
                for _ in range(2):
                    await RisingEdge(dut.clk)
                    assert int(dut.done.value) == 0, "done is not a one-cycle pulse"
                    assert int(dut.result_valid.value) == 0, "Extra result after done"
                await FallingEdge(dut.clk)
                dut.result_ready.value = 0
                return
        raise AssertionError("Timed out waiting for done")

    async def run(self, kind="random", gaps=False, backpressure=False):
        matrix_a, matrix_b = self.matrices(kind)
        monitor = cocotb.start_soon(self.collect(
            self.expected(matrix_a, matrix_b), backpressure))
        try:
            await self.start()
            await self.load_weights(matrix_b, gaps)
            await self.stream_activations(matrix_a, gaps)
            await monitor
        finally:
            if not monitor.done():
                monitor.kill()


async def setup(dut):
    dut.clk.value = 0
    dut.rst_n.value = 0
    for name in ("start", "weight_valid", "act_valid", "result_ready",
                 "weight_data", "act_data"):
        getattr(dut, name).value = 0
    bench = MatrixBench(dut)
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await bench.reset()
    return bench


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_simple_values(dut):
    bench = await setup(dut)
    await bench.run("simple")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_identity_matrix(dut):
    bench = await setup(dut)
    await bench.run("identity")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_random_matrices(dut):
    bench = await setup(dut)
    for _ in range(5):
        await bench.run()


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_zero_matrix(dut):
    bench = await setup(dut)
    await bench.run("zero")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_signed_values(dut):
    bench = await setup(dut)
    if bench.signed_math:
        await bench.run("signed")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_numeric_limits(dut):
    bench = await setup(dut)
    await bench.run("limits")
    await bench.run("overflow")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_input_gaps(dut):
    bench = await setup(dut)
    await bench.run(gaps=True)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_output_backpressure(dut):
    bench = await setup(dut)
    await bench.run(backpressure=True)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_stalls(dut):
    bench = await setup(dut)
    await bench.run(gaps=True, backpressure=True)


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_back_to_back(dut):
    bench = await setup(dut)
    await bench.run("simple")
    await bench.run("zero")
    await bench.run("random")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_reset_during_weights(dut):
    bench = await setup(dut)
    _, weights = bench.matrices()
    await bench.start()
    await bench.send("weight", bench.pack(weights[0], bench.weight_width))
    await bench.reset()
    await bench.run("simple")


@cocotb.test(timeout_time=1, timeout_unit="ms")
async def test_reset_during_compute(dut):
    bench = await setup(dut)
    activations, weights = bench.matrices()
    await bench.start()
    await bench.load_weights(weights)
    await bench.send("act", bench.activation_word(activations, 0))
    await bench.reset()
    await bench.run("simple")
