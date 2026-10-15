# Linear Linked-List Hardware Verification

The standalone Singly and Doubly benches share `linked_list_tb.py` and
`linked_list_tb.svh`. These are verification models; the DUTs remain separate,
self-contained synthesizable SystemVerilog modules.

## Hardware Contract

The node pool contains `MAX_NODE` fixed storage slots. Addresses remain stable
until deletion. Both lists end at `NULL = MAX_NODE`; DLL also has
`head.prev = NULL`. A singleton has NULL links, and an empty list has
`head = tail = NULL`. Insertions allocate the lowest free physical slot.

`ADDR_WIDTH = ceil(log2(MAX_NODE+1))` represents both NULL and a full length,
including `MAX_NODE=1`. All opcodes and external ports are preserved.

| Code | Operation | Meaning |
|------|-----------|---------|
| 0 | Read address | Return an occupied node's data and neighbour pointer(s) |
| 1 | Insert address | Insert before an occupied address; addresses at/above NULL append |
| 2 | Delete value | Remove the first matching value from the head |
| 3 | Delete address | Remove the node at that occupied physical address |
| 5 | Insert index | Insert before the zero-based index; indices at/above length append |
| 7 | Delete index | Remove the node at a valid zero-based index |

Codes 4/6, missing values, invalid reads/deletions, vacant address-insertion
targets, and full-pool insertions fault without altering the list.
An empty list can be created with index insertion or a NULL address append.

## Clocked Requests

Drive `op_start` for one rising edge with stable `op/addr_in/data_in`.
The controller latches the command, ignores requests while executing and on
the completion cycle, and pulses `op_done` with the final `fault`.
Wait for completion to clear before issuing the next request. Existing
clients may hold the original request until completion; holding start into
a later idle cycle submits another operation.

Data and pointer outputs update only on a successful read and otherwise hold
their previous values, including after failed reads. Asynchronous active-high
reset aborts the operation, clears the pool and data output, and sets pointer
outputs to NULL. Reset makes `empty=1`, `full=0`.

All links, validity bits, length, head and tail commit together with completion.
Traversal uses one node visit per clock, with a length-bounded counter.
Measured in rising-edge samples, including acceptance and completion:

| Path | Maximum samples |
|------|-----------------|
| Read / error detected before traversal | 2 |
| Append | 3 |
| SLL indexed insert/delete at occupied index i | i + 4 |
| DLL indexed insert/delete at occupied index i | min(i, length-1-i) + 4 |
| Successful value deletion at first-match index i | i + 4 |
| Missing value in a nonempty list | length + 2 |

SLL stores next pointers and uses a predecessor register during traversal;
it has no per-node previous-pointer array. DLL stores both links, supports
constant-cycle address updates, and starts indexed walks at the nearer end.
All RTL loops have parameter-fixed bounds for reset or the free-slot priority
encoder; runtime searches advance through FSM states.

Both implementations use asynchronous-read, resettable register arrays.
Per-node storage totals `N*(DATA_WIDTH+ADDR_WIDTH+1)` bits for SLL and
`N*(DATA_WIDTH+2*ADDR_WIDTH+1)` for DLL, plus control/output registers.
This architecture maps to flip-flops and multiplexers in the tested flow;
inferring block RAM requires a different port and read-latency design.

## Running Verification

From the repository root in Linux/WSL:

```bash
python3 Utils/tb/linked_list/regress_rtl.py
python3 Utils/tb/linked_list/regress_rtl.py --synth-only
python3 Utils/tb/linked_list/regress_rtl.py --module singly
make -C Doubly_Linked_List/tb/sv sim SEED=123 TEST=traversal
make -C Singly_Linked_List/tb/cocotb SEED=123
make -C Doubly_Linked_List/tb/sv netlist_sim MAX_NODE=5 DATA_WIDTH=17
```

Install Make, Bash, Icarus Verilog, Python, cocotb and Yosys.
`netlist_sim` uses Yosys's local Xilinx cell models; override
`YOSYS_DATDIR` if they are installed outside `/usr/share/yosys`.
It runs the same reference-model SV suite on the mapped netlist.

Both benches accept `MAX_NODE`, `DATA_WIDTH`, `SEED`, `WAVES=1`, and
`TB_TIMEOUT_CYCLES`. Clean before changing parameters in a reused build
directory. SV `TEST` accepts `all`, `empty`, `singleton`, `insert`,
`delete`, `reuse`, `traversal`, `random`, `reset`, `outputs`, and `held`.
The cocotb default `check` target rejects failed or empty XML results.

The runner compiles actual source files into independent temporary directories,
checks every occupied/vacant address and neighbour link, and uses two workers.
It covers eight capacity/width combinations per module, SV seeds 0/1/19,
cocotb seeds 0 through 9, waveform generation and deliberately rejected
operation timeouts. Each cocotb run executes ten scenarios; both benches
check pulses, held requests, changed inputs, ignored busy requests, duplicate
deletion, reset, output retention, and 200 random operations.

The operation bound is `min(TB_TIMEOUT_CYCLES, MAX_NODE+4)` clock samples;
DLL indexed operations also enforce the nearer-end latency bound.
`RTL_RUN_TIMEOUT` controls the separate host-time limit (default 180 seconds).
Generated results stay in ignored build directories or temporary directories.

## Recorded Results

Validated on 2026-10-15 with Icarus Verilog 11.0, cocotb 1.8.1 and Yosys 0.9:

- All 62 real-RTL runs pass (31 per module), with all ten cocotb scenarios
  executed in every full cocotb run.
- Default `MAX_NODE=8`, `DATA_WIDTH=8`, `SEED=123`: SV passes 2,801 SLL
  transactions and 2,817 DLL transactions. Both default mapped netlists
  pass the same SV transactions.
- All eight Xilinx synthesis configurations pass structural checks and
  no-latch assertions before and after technology mapping: 8/8, 1/1,
  5/17 and 33/8 capacity/data-width pairs for each module.
- All six mapped-netlist functional simulations pass: capacity/width
  pairs 8/8, 1/1 and 5/17 for each module.
- All four deliberately forced timeout checks are rejected by Make.

Default synthesis estimates in this Yosys flow:

| Module | Flip-flops (FDCE + FDPE) | Estimated logic cells |
|--------|-------------------------|-----------------------|
| Singly | 170 | 367 |
| Doubly | 204 | 695 |

The new suite was first run against the original RTL and exposed request
latching, fault/read-output and pointer-handling failures before repair.
The mapped-netlist simulations are functional checks with no SDF annotation;
placement, routing and static timing analysis are outside these results.
