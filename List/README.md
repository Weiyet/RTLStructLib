# List Module

## Overview

A parameterized register-backed list with indexed reads, insertion, deletion,
unsigned searches, full-width summation, and ascending/descending insertion sort.
All three summation methods are implemented. Lane zero occupies the least
significant bits of the packed helper-module interfaces.

## Parameters and Sources

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `DATA_WIDTH` | 32 | Unsigned element width; at least 1 |
| `LENGTH` | 8 | Capacity; any positive integer, including 1 |
| `SUM_METHOD` | 0 | 0: combinational sum, 1: sequential sum, 2: registered balanced adder tree |

`INDEX_WIDTH = max(1, ceil(log2(LENGTH)))`. The output width is
`DATA_WIDTH + INDEX_WIDTH`, sufficient for the maximum unsigned sum.
`len` uses `ceil(log2(LENGTH+1))` bits.

Include all files in `src/rtl_src.f`: `list.sv` manages transactions,
`adder.sv` implements summation, and `sorter.sv` performs insertion sort.
Storage and intermediate arithmetic stages map to registers in the tested
Yosys flow.

## Interface and Operations

| Port | Direction | Description |
|------|-----------|-------------|
| `clk`, `rst` | Input | Rising-edge clock; asynchronous active-high reset |
| `op_sel[2:0]`, `op_en` | Input | Operation code and request enable |
| `data_in` | Input | Element to insert or search |
| `index_in` | Input | Unsigned index, `INDEX_WIDTH` bits |
| `data_out` | Output | Read value, search index, or unsigned sum |
| `op_done` | Output | Completion; also marks intermediate find-all matches |
| `op_in_progress` | Output | A multicycle operation is running |
| `op_error` | Output | Invalid read/delete, full insertion, or search with no matches |
| `len` | Output | Number of occupied elements |

| `op_sel` | Operation | Behavior |
|------------|-----------|----------|
| 0 | Read | Return the element at an occupied index |
| 1 | Insert | Shift elements right; indices at/beyond `len` append |
| 2 | Find all | Report matching indices in ascending index order |
| 3 | Find first | Return the lowest matching index |
| 4 | Sum | Sum occupied elements; empty lists return zero |
| 5 / 6 | Sort ascending / descending | Reorder occupied elements using unsigned comparisons |
| 7 | Delete | Remove an occupied element and shift the remainder left |

Failed operations preserve the contents and length. Empty searches complete
with an error; empty and single-element sorts complete successfully.
Reset clears storage, length, outputs, and any pending operation.

## Request and Completion Timing

Present the command before a rising edge in idle, with `op_en=1`; a one-cycle
request is sufficient. Inputs are captured for multicycle operations.
Requests while busy are ignored. After final completion, allow one clock
for `op_done` to clear before issuing the next request. Holding `op_en` high
into idle can issue another operation.

For find-all, sample every clock with `op_done && op_in_progress`: each such
clock reports one matching index, including consecutive matches.
`op_done && !op_in_progress` is the final completion, with `op_error=1`
only if there were no matches; its `data_out` does not add another match.

Read, insert, delete, and combinational sum complete on the acceptance edge.
Sequential sum completes `LENGTH+1` clocks later; the registered tree
completes `ceil(log2(LENGTH))+3` clocks later. The tree zero-pads non-power-of-two
capacities and preserves carry bits at every stage. Search takes linear time;
insertion sort takes quadratic time in the occupied length.

## Build and Verification

Run in Linux/WSL with Make, Bash, Icarus Verilog, Python, cocotb, and Yosys:

```bash
make -C List/tb/sv sim SEED=123 SUM_METHOD=1
make -C List/tb/cocotb SEED=123 SUM_METHOD=2
python3 List/tb/support/regress_rtl.py
make -C List/tb/sv synth SUM_METHOD=2 LENGTH=5 DATA_WIDTH=17
```

Both benches accept `DATA_WIDTH`, `LENGTH`, `SUM_METHOD`, `SEED`, and
`WAVES=1`. Clean before changing parameters in a reused build directory.
The SV `TEST` selector accepts `all`, `empty`, `boundaries`, `search`,
`sum`, `sort`, `random`, and `reset`. Build products remain in ignored
`sim_build/` directories. Use the default cocotb `check` target, which
reuses the repository's XML result checker and returns nonzero on failed tests.

The regression checks the real RTL in both benches across all sum methods,
six capacity/width combinations, and seeds 0, 1, 19, and 123.
It also checks waveform generation and verifies both Makefiles reject
deliberately forced completion timeouts.

Validated on 2026-10-14 with Icarus Verilog 11.0, cocotb 1.8.1, and Yosys 0.9:

- All 7 cocotb scenarios pass for each sum method at `LENGTH=8`,
  `DATA_WIDTH=8`, `SEED=123`; SV passes 603 transactions per method.
- All 56 real-RTL regression runs and both forced-timeout checks pass.
- Xilinx synthesis, structural checks, and no-latch assertions pass for
  all three methods at 8 elements / 8 bits, and for the tree at
  1 element / 1 bit and 5 elements / 17 bits.

Before repair, the same default cocotb suite passed 4/7, 2/7, and 1/7
scenarios for methods 0, 1, and 2 respectively. It exposed empty-operation
timeouts, changing search inputs, stale sequential sums, and truncated or
incorrect tree sums. Gate-level simulation and routed timing are not measured.

