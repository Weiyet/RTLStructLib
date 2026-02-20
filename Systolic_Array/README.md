# Systolic Array

A production-ready, parameterized systolic array implementation for matrix multiplication in SystemVerilog. This design uses weight-stationary dataflow, commonly found in AI accelerators like Google's TPU, and is suitable for FPGA and ASIC synthesis.

## Features

- **Configurable array dimensions** (rows × columns)
- **Weight-stationary dataflow** - weights loaded once, activations streamed
- **Parameterized data widths** for activations, weights, and accumulators
- **Automatic input skewing** for proper systolic operation
- **Signed/unsigned arithmetic** support
- **AXI-Stream-like handshaking** for easy integration
- **Fully synchronous design** with active-low reset
- **Modular architecture** - PE, array core, and top wrapper

## Architecture

```
              Weight Inputs (top)
                    ↓ ↓ ↓ ↓
              +---+---+---+---+
    Act → →   |PE |PE |PE |PE | → → (cascade)
              +---+---+---+---+
    Act → →   |PE |PE |PE |PE | → →
              +---+---+---+---+
    Act → →   |PE |PE |PE |PE | → →
              +---+---+---+---+
    Act → →   |PE |PE |PE |PE | → →
              +---+---+---+---+
                    ↓ ↓ ↓ ↓
              Result Outputs (bottom)
```

### Dataflow

1. **Weight Loading**: Weights from matrix B are loaded into PEs column-by-column
2. **Computation**: Activations from matrix A stream left-to-right with automatic skewing
3. **Accumulation**: Partial sums flow top-to-bottom through each column
4. **Result Extraction**: Final results emerge from the bottom after drain cycles

## Files

| File | Description |
|------|-------------|
| `src/pe.sv` | Processing Element - MAC unit with weight register |
| `src/systolic_array.sv` | 2D array of PEs with interconnects |
| `src/systolic_array_top.sv` | Top wrapper with FSM and handshaking |

## Parameters

### Top Module (`systolic_array_top`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| ARRAY_ROWS | Number of PE rows (M dimension tile) | 4 |
| ARRAY_COLS | Number of PE columns (N dimension tile) | 4 |
| K_DIM | Inner/reduction dimension | 4 |
| DATA_WIDTH | Activation bit width | 8 |
| WEIGHT_WIDTH | Weight bit width | 8 |
| ACC_WIDTH | Accumulator bit width | 32 |
| SIGNED_MATH | Enable signed arithmetic (1) or unsigned (0) | 1 |
| INPUT_SKEW | Auto-skew inputs (1) or assume pre-skewed (0) | 1 |

### Processing Element (`pe`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| DATA_WIDTH | Input activation bit width | 8 |
| WEIGHT_WIDTH | Weight bit width | 8 |
| ACC_WIDTH | Accumulator bit width | 32 |
| SIGNED_MATH | Signed (1) or unsigned (0) arithmetic | 1 |

## Interface Signals

### Control Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| clk | Input | 1 | System clock |
| rst_n | Input | 1 | Active-low synchronous reset |
| start | Input | 1 | Start computation pulse |
| busy | Output | 1 | Operation in progress |
| done | Output | 1 | Computation complete pulse |

### Weight Loading Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| weight_data | Input | ARRAY_COLS × WEIGHT_WIDTH | One row of weights |
| weight_valid | Input | 1 | Weight data valid |
| weight_ready | Output | 1 | Ready to accept weights |

### Activation Streaming Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| act_data | Input | ARRAY_ROWS × DATA_WIDTH | One column of activations |
| act_valid | Input | 1 | Activation data valid |
| act_ready | Output | 1 | Ready to accept activations |

### Result Output Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| result_data | Output | ARRAY_COLS × ACC_WIDTH | One row of results |
| result_valid | Output | 1 | Result data valid |
| result_ready | Input | 1 | Downstream ready for results |

## Usage Example

```verilog
// Instantiate a 4x4 systolic array for 8-bit signed matrix multiplication
systolic_array_top #(
    .ARRAY_ROWS     (4),
    .ARRAY_COLS     (4),
    .K_DIM          (4),
    .DATA_WIDTH     (8),
    .WEIGHT_WIDTH   (8),
    .ACC_WIDTH      (32),
    .SIGNED_MATH    (1),
    .INPUT_SKEW     (1)
) u_systolic_array (
    .clk            (clk),
    .rst_n          (rst_n),

    // Control
    .start          (start),
    .busy           (busy),
    .done           (done),

    // Weight loading
    .weight_data    (weight_data),
    .weight_valid   (weight_valid),
    .weight_ready   (weight_ready),

    // Activation streaming
    .act_data       (act_data),
    .act_valid      (act_valid),
    .act_ready      (act_ready),

    // Results
    .result_data    (result_data),
    .result_valid   (result_valid),
    .result_ready   (result_ready)
);
```

## Operation Sequence

### 1. Weight Loading Phase
```
for k = 0 to K_DIM-1:
    for row = 0 to ARRAY_ROWS-1:
        weight_data = B[row][k*ARRAY_COLS : (k+1)*ARRAY_COLS-1]
        weight_valid = 1
        wait(weight_ready)
```

### 2. Computation Phase
```
for k = 0 to K_DIM-1:
    act_data = A[0:ARRAY_ROWS-1][k]  // Column k of activation matrix
    act_valid = 1
    wait(act_ready)
```

### 3. Result Collection
```
while (!done):
    if (result_valid && result_ready):
        store result_data
```

## Design Notes

### 1. Matrix Dimensions
For computing C = A × B where A is (M × K) and B is (K × N):
- Configure `ARRAY_ROWS` ≤ M (number of output rows per tile)
- Configure `ARRAY_COLS` ≤ N (number of output columns per tile)
- Configure `K_DIM` = K (reduction dimension)

For matrices larger than the array, tile the computation and accumulate partial results.

### 2. Input Skewing
The systolic array requires input data to be "skewed" so that data arrives at each PE at the correct time:
- Row 0: No delay
- Row 1: 1 cycle delay
- Row N: N cycles delay

When `INPUT_SKEW=1` (default), this is handled automatically. Set to 0 if providing pre-skewed data.

### 3. Accumulator Width
To prevent overflow, set `ACC_WIDTH` to accommodate:
```
ACC_WIDTH ≥ DATA_WIDTH + WEIGHT_WIDTH + ceil(log2(K_DIM))
```

For 8-bit inputs and K_DIM=128: ACC_WIDTH ≥ 8 + 8 + 7 = 23 bits (use 32 for safety).

### 4. Weight-Stationary Tradeoffs
**Advantages:**
- Weights loaded once, reused across all activation rows
- Efficient for inference with fixed weights
- Lower memory bandwidth for weights

**Considerations:**
- Weight loading adds latency before computation
- Best when weight matrix changes infrequently

### 5. Pipelining and Throughput
- Array latency: `ARRAY_ROWS + K_DIM` cycles after activations start
- Throughput: 1 result column per cycle during drain phase
- Multiple matrices can be pipelined by overlapping weight loads

## Resource Utilization

The design scales approximately as:
- **Registers**: O(ARRAY_ROWS × ARRAY_COLS × (DATA_WIDTH + WEIGHT_WIDTH + ACC_WIDTH))
- **DSP blocks**: O(ARRAY_ROWS × ARRAY_COLS) (one multiplier per PE)
- **LUTs**: O(ARRAY_ROWS × ARRAY_COLS × ACC_WIDTH) for adders

### Example (Xilinx 7-Series, 4×4 array, 8-bit data):
| Resource | Count |
|----------|-------|
| LUT | ~500 |
| FF | ~800 |
| DSP48 | 16 |

## Limitations

1. **Single clock domain**: Design assumes single clock for all operations
2. **Fixed K dimension**: K_DIM must be set at synthesis time
3. **No output buffering**: Downstream must be ready when results are valid
4. **Rectangular arrays only**: ARRAY_ROWS and ARRAY_COLS are independent

## References

1. H.T. Kung, "Why Systolic Architectures?", Computer, 1982
2. N. Jouppi et al., "In-Datacenter Performance Analysis of a Tensor Processing Unit", ISCA 2017
3. Y. Chen et al., "Eyeriss: An Energy-Efficient Reconfigurable Accelerator for Deep CNNs", ISSCC 2016
