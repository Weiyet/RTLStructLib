"""
Cocotb testbench for Systolic Array matrix multiplication.

Tests:
1. Simple matrix multiplication with known values
2. Identity matrix multiplication
3. Random matrix multiplication
4. Edge cases (zeros, signed values)
"""

import random
import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.clock import Clock

# Default parameters (overridden by DUT parameters)
ARRAY_ROWS = 4
ARRAY_COLS = 4
K_DIM = 4
DATA_WIDTH = 8
WEIGHT_WIDTH = 8
ACC_WIDTH = 32
SIGNED_MATH = 1

CLK_PERIOD = 10  # ns
err_cnt = 0


def signed_value(val, width):
    """Convert unsigned to signed value."""
    if val >= (1 << (width - 1)):
        return val - (1 << width)
    return val


def to_unsigned(val, width):
    """Convert signed to unsigned value."""
    if val < 0:
        return val + (1 << width)
    return val


async def dut_init(dut):
    """Initialize DUT and start clock."""
    global ARRAY_ROWS, ARRAY_COLS, K_DIM, DATA_WIDTH, WEIGHT_WIDTH, ACC_WIDTH, SIGNED_MATH

    # Read parameters from DUT
    ARRAY_ROWS = dut.ARRAY_ROWS.value
    ARRAY_COLS = dut.ARRAY_COLS.value
    K_DIM = dut.K_DIM.value
    DATA_WIDTH = dut.DATA_WIDTH.value
    WEIGHT_WIDTH = dut.WEIGHT_WIDTH.value
    ACC_WIDTH = dut.ACC_WIDTH.value
    SIGNED_MATH = dut.SIGNED_MATH.value

    dut._log.info(f"Array Size: {ARRAY_ROWS}x{ARRAY_COLS}, K={K_DIM}")
    dut._log.info(f"Data Width: {DATA_WIDTH}, Weight Width: {WEIGHT_WIDTH}, Acc Width: {ACC_WIDTH}")
    dut._log.info(f"Signed Math: {SIGNED_MATH}")

    # Start clock
    await cocotb.start(Clock(dut.clk, CLK_PERIOD, units="ns").start())

    # Initialize signals
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.weight_data.value = 0
    dut.weight_valid.value = 0
    dut.act_data.value = 0
    dut.act_valid.value = 0
    dut.result_ready.value = 0

    # Reset sequence
    await Timer(100, 'ns')
    dut.rst_n.value = 1
    await Timer(100, 'ns')


def compute_expected_result(matrix_a, matrix_b):
    """Compute expected matrix multiplication result."""
    result = [[0] * ARRAY_COLS for _ in range(ARRAY_ROWS)]

    for i in range(ARRAY_ROWS):
        for j in range(ARRAY_COLS):
            acc = 0
            for k in range(K_DIM):
                if SIGNED_MATH:
                    a_val = signed_value(matrix_a[i][k], DATA_WIDTH)
                    b_val = signed_value(matrix_b[k][j], WEIGHT_WIDTH)
                else:
                    a_val = matrix_a[i][k]
                    b_val = matrix_b[k][j]
                acc += a_val * b_val
            result[i][j] = acc

    return result


async def load_weights(dut, matrix_b):
    """Load weight matrix into systolic array."""
    dut._log.info("Loading weights...")

    # Wait for weight_ready
    while dut.weight_ready.value != 1:
        await RisingEdge(dut.clk)

    # Load weights: K dimension outer, rows inner
    for k in range(K_DIM):
        for row in range(ARRAY_ROWS):
            await RisingEdge(dut.clk)

            # Pack all columns
            weight_packed = 0
            for col in range(ARRAY_COLS):
                weight_packed |= (matrix_b[k][col] & ((1 << WEIGHT_WIDTH) - 1)) << (col * WEIGHT_WIDTH)

            dut.weight_data.value = weight_packed
            dut.weight_valid.value = 1

    await RisingEdge(dut.clk)
    dut.weight_valid.value = 0
    dut.weight_data.value = 0
    dut._log.info("Weight loading complete")


async def stream_activations(dut, matrix_a):
    """Stream activation matrix into systolic array."""
    dut._log.info("Streaming activations...")

    # Wait for act_ready
    while dut.act_ready.value != 1:
        await RisingEdge(dut.clk)

    # Stream column by column (K dimension)
    for k in range(K_DIM):
        await RisingEdge(dut.clk)

        # Pack all rows
        act_packed = 0
        for row in range(ARRAY_ROWS):
            act_packed |= (matrix_a[row][k] & ((1 << DATA_WIDTH) - 1)) << (row * DATA_WIDTH)

        dut.act_data.value = act_packed
        dut.act_valid.value = 1

    await RisingEdge(dut.clk)
    dut.act_valid.value = 0
    dut.act_data.value = 0
    dut._log.info("Activation streaming complete")


async def collect_results(dut):
    """Collect results from systolic array."""
    dut._log.info("Collecting results...")

    results = []
    dut.result_ready.value = 1
    timeout = 0

    while dut.done.value != 1 and timeout < 1000:
        await RisingEdge(dut.clk)
        timeout += 1

        if dut.result_valid.value == 1:
            # Unpack result row
            result_packed = dut.result_data.value.integer
            row_result = []
            for col in range(ARRAY_COLS):
                val = (result_packed >> (col * ACC_WIDTH)) & ((1 << ACC_WIDTH) - 1)
                if SIGNED_MATH:
                    val = signed_value(val, ACC_WIDTH)
                row_result.append(val)
            results.append(row_result)
            dut._log.info(f"Received result row: {row_result}")

    dut.result_ready.value = 0
    dut._log.info("Result collection complete")
    return results


async def run_matmul_test(dut, matrix_a, matrix_b, test_name):
    """Run a single matrix multiplication test."""
    global err_cnt

    dut._log.info(f"\n{'='*50}")
    dut._log.info(f"Test: {test_name}")
    dut._log.info(f"{'='*50}")

    # Print matrices
    dut._log.info(f"Matrix A ({ARRAY_ROWS}x{K_DIM}):")
    for row in matrix_a:
        if SIGNED_MATH:
            dut._log.info(f"  {[signed_value(v, DATA_WIDTH) for v in row]}")
        else:
            dut._log.info(f"  {row}")

    dut._log.info(f"Matrix B ({K_DIM}x{ARRAY_COLS}):")
    for row in matrix_b:
        if SIGNED_MATH:
            dut._log.info(f"  {[signed_value(v, WEIGHT_WIDTH) for v in row]}")
        else:
            dut._log.info(f"  {row}")

    # Compute expected result
    expected = compute_expected_result(matrix_a, matrix_b)
    dut._log.info(f"Expected C ({ARRAY_ROWS}x{ARRAY_COLS}):")
    for row in expected:
        dut._log.info(f"  {row}")

    # Start computation
    await RisingEdge(dut.clk)
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    # Wait for busy
    while dut.busy.value != 1:
        await RisingEdge(dut.clk)

    # Run load, stream, and collect concurrently
    await load_weights(dut, matrix_b)
    await stream_activations(dut, matrix_a)
    actual = await collect_results(dut)

    # Wait for done
    while dut.done.value != 1:
        await RisingEdge(dut.clk)

    # Compare results
    local_err = 0
    dut._log.info("\n--- Result Comparison ---")

    if len(actual) > 0:
        for i in range(min(len(actual), ARRAY_ROWS)):
            for j in range(ARRAY_COLS):
                if actual[i][j] != expected[i][j]:
                    dut._log.error(f"C[{i}][{j}] mismatch: Expected {expected[i][j]}, Got {actual[i][j]}")
                    local_err += 1
                    err_cnt += 1
    else:
        dut._log.warning("No results collected")

    if local_err == 0:
        dut._log.info(f"Test '{test_name}': PASSED")
    else:
        dut._log.error(f"Test '{test_name}': FAILED with {local_err} errors")

    # Wait between tests
    for _ in range(10):
        await RisingEdge(dut.clk)

    return local_err == 0


def generate_simple_matrices():
    """Generate simple test matrices with known values."""
    matrix_a = [[i * K_DIM + k + 1 for k in range(K_DIM)] for i in range(ARRAY_ROWS)]
    matrix_b = [[k * ARRAY_COLS + j + 1 for j in range(ARRAY_COLS)] for k in range(K_DIM)]

    # Convert to unsigned representation
    for i in range(ARRAY_ROWS):
        for k in range(K_DIM):
            matrix_a[i][k] = to_unsigned(matrix_a[i][k], DATA_WIDTH) if matrix_a[i][k] < 0 else matrix_a[i][k]

    for k in range(K_DIM):
        for j in range(ARRAY_COLS):
            matrix_b[k][j] = to_unsigned(matrix_b[k][j], WEIGHT_WIDTH) if matrix_b[k][j] < 0 else matrix_b[k][j]

    return matrix_a, matrix_b


def generate_identity_matrices():
    """Generate identity matrix test."""
    matrix_a = [[random.randint(1, 10) for _ in range(K_DIM)] for _ in range(ARRAY_ROWS)]
    matrix_b = [[1 if k == j else 0 for j in range(ARRAY_COLS)] for k in range(K_DIM)]
    return matrix_a, matrix_b


def generate_random_matrices():
    """Generate random test matrices."""
    max_val = (1 << DATA_WIDTH) - 1
    matrix_a = [[random.randint(0, max_val) for _ in range(K_DIM)] for _ in range(ARRAY_ROWS)]
    matrix_b = [[random.randint(0, max_val) for _ in range(ARRAY_COLS)] for _ in range(K_DIM)]
    return matrix_a, matrix_b


def generate_zero_matrices():
    """Generate zero matrix test."""
    matrix_a = [[0 for _ in range(K_DIM)] for _ in range(ARRAY_ROWS)]
    matrix_b = [[random.randint(1, 10) for _ in range(ARRAY_COLS)] for _ in range(K_DIM)]
    return matrix_a, matrix_b


def generate_signed_matrices():
    """Generate matrices with positive and negative values."""
    matrix_a = []
    for i in range(ARRAY_ROWS):
        row = []
        for k in range(K_DIM):
            val = (k + 1) if ((i + k) % 2 == 0) else -(k + 1)
            row.append(to_unsigned(val, DATA_WIDTH))
        matrix_a.append(row)

    matrix_b = []
    for k in range(K_DIM):
        row = []
        for j in range(ARRAY_COLS):
            val = (j + 1) if ((k + j) % 2 == 0) else -(j + 1)
            row.append(to_unsigned(val, WEIGHT_WIDTH))
        matrix_b.append(row)

    return matrix_a, matrix_b


@cocotb.test()
async def test_simple_values(dut):
    """Test with simple known values."""
    await dut_init(dut)
    matrix_a, matrix_b = generate_simple_matrices()
    await run_matmul_test(dut, matrix_a, matrix_b, "Simple Known Values")

    if err_cnt > 0:
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")


@cocotb.test()
async def test_identity_matrix(dut):
    """Test with identity matrix."""
    global err_cnt
    err_cnt = 0
    await dut_init(dut)
    matrix_a, matrix_b = generate_identity_matrices()
    await run_matmul_test(dut, matrix_a, matrix_b, "Identity Matrix")

    if err_cnt > 0:
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")


@cocotb.test()
async def test_random_matrices(dut):
    """Test with random matrices."""
    global err_cnt
    err_cnt = 0
    await dut_init(dut)
    matrix_a, matrix_b = generate_random_matrices()
    await run_matmul_test(dut, matrix_a, matrix_b, "Random Matrices")

    if err_cnt > 0:
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")


@cocotb.test()
async def test_zero_matrix(dut):
    """Test with zero matrix."""
    global err_cnt
    err_cnt = 0
    await dut_init(dut)
    matrix_a, matrix_b = generate_zero_matrices()
    await run_matmul_test(dut, matrix_a, matrix_b, "Zero Matrix")

    if err_cnt > 0:
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")


@cocotb.test()
async def test_signed_values(dut):
    """Test with signed values."""
    global err_cnt
    err_cnt = 0
    await dut_init(dut)

    if SIGNED_MATH:
        matrix_a, matrix_b = generate_signed_matrices()
        await run_matmul_test(dut, matrix_a, matrix_b, "Signed Values")
    else:
        dut._log.info("Skipping signed test (SIGNED_MATH=0)")

    if err_cnt > 0:
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")
