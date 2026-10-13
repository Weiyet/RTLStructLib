# Systolic Array

A parameterized matrix multiplier built around a weight-stationary SystemVerilog
PE array. The repaired RTL passes the functional regression and synthesis
checks described in [the verification guide](tb/README.md).

## Architecture

The top computes C = A * B with M = ARRAY_ROWS, N = ARRAY_COLS and K = K_DIM.
It buffers A[M,K] and B[K,N], then processes K in tiles of ARRAY_ROWS.
Within the physical array, each PE row represents one reduction index.
Weights remain stationary during a tile; activations move horizontally and
partial sums move vertically.

The wrapper transposes and skews buffered activations for the PE schedule,
captures each column at its own pipeline delay, and adds successive K tiles
into C[M,N]. Incomplete tiles are padded with zero. Result buffering separates
computation from downstream backpressure.

| File | Responsibility |
|------|----------------|
| `src/pe.sv` | Weight register, signed/unsigned MAC and pipeline stage |
| `src/systolic_array.sv` | Physical PE grid and interconnect |
| `src/systolic_array_top.sv` | Input buffering, tile scheduling and result handshake |
| `src/rtl_list.f` | Integration source list |

## Parameters

| Parameter | Meaning | Default |
|-----------|---------|---------|
| ARRAY_ROWS | Output rows M and physical PE rows per K tile | 4 |
| ARRAY_COLS | Output columns N and physical PE columns | 4 |
| K_DIM | Reduction dimension; may be smaller or larger than ARRAY_ROWS | 4 |
| DATA_WIDTH | Activation bits per lane | 8 |
| WEIGHT_WIDTH | Weight bits per lane | 8 |
| ACC_WIDTH | Partial-sum and result width | 32 |
| SIGNED_MATH | 1: two's complement; 0: unsigned | 1 |
| INPUT_SKEW | 1: ordinary input columns; 0: externally skewed input columns | 1 |

Dimensions and operand widths must be positive. ACC_WIDTH must be at least
DATA_WIDTH + WEIGHT_WIDTH. Arithmetic wraps modulo 2^ACC_WIDTH. For a
conservative no-overflow bound, use DATA_WIDTH + WEIGHT_WIDTH + ceil(log2(K_DIM)).

## Ports and Transaction Sequence

All transfers occur on a rising clock edge with valid and ready both high.
Lane zero occupies the least significant bits. Reset is asynchronous and
active-low; it aborts the current transaction.

1. Pulse `start` when `busy=0` and `done=0`.
2. Send each packed row B[k,:] **ARRAY_ROWS times**, in increasing k order.
   This preserves the original loading protocol: K*M accepted weight beats.
3. With INPUT_SKEW=1, send K packed activation columns A[:,k].
   With INPUT_SKEW=0, send K+M-1 beats: lane r on beat t carries A[r,t-r]
   when that index is in range. Padding lanes are ignored. Skew advances on
   accepted beats, so input gaps are supported in either mode.
4. Accept exactly M packed output rows C[m,:], in increasing m order.
   The DUT holds `result_valid` and `result_data` until `result_ready`.
5. `done` pulses for one cycle after the final result transfer, with `busy` low.
   Start the next job in the following idle cycle.

The wrapper loads weights before accepting activations. It accepts one job at
a time; weight loading, computation and output are separate phases.

## Latency and Storage

Each K tile takes ARRAY_ROWS weight-load clocks, one pipeline-clear clock,
and 2*ARRAY_ROWS+ARRAY_COLS-1 run clocks. The first output becomes valid
ceil(K_DIM/ARRAY_ROWS)*(3*ARRAY_ROWS+ARRAY_COLS) clocks after the final
activation transfer. Input gaps and output stalls add external transaction time.

Matrix buffers require M*K*DATA_WIDTH + K*N*WEIGHT_WIDTH + M*N*ACC_WIDTH
bits, in addition to PE state. The current synthesis flow maps these buffers
to registers. Size large configurations with this storage cost in mind.

Default `make synth` with Yosys 0.9 reported 1,555 flip-flops and 8,539
estimated logic cells, with no structural errors or latches. These are
tool-specific synthesis counts; routed timing and resource use depend on
the target and implementation flow.

## Verification

From the repository root in Linux/WSL:

```bash
make -C Systolic_Array/tb/sv sim SEED=123
make -C Systolic_Array/tb/cocotb SEED=123
python3 Systolic_Array/tb/support/regress_rtl.py
python3 Systolic_Array/tb/support/check_benches.py
make -C Systolic_Array/tb/sv synth
```

The real-RTL regression covers ten configurations in both benches and twenty
additional cocotb seeds. Coverage includes rectangular arrays, short/partial K
tiles, both skew modes, signed/unsigned arithmetic, accumulator wrap, input
gaps, output stalls, consecutive jobs and reset recovery. Parameters are fixed
at elaboration; larger M/N matrices require host-managed output tiling.
