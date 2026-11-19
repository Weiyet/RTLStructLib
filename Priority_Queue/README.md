# Priority Queue

`priority_queue` is a bounded, synthesizable binary heap of unsigned
`{priority, data}` entries. It supports insertion, removal of the best entry,
and non-destructive inspection. Smaller priorities win by default.

## Parameters

| Parameter | Default | Contract |
|---|---:|---|
| `DEPTH` | 16 | Positive capacity; arbitrary depths, including 1, are supported |
| `PRIORITY_WIDTH` | 8 | Positive unsigned priority width |
| `DATA_WIDTH` | 8 | Positive opaque payload width |
| `MIN_FIRST` | 1 | 1: minimum first; 0: maximum first |

Equal priorities are allowed. Comparisons are strict and the left child wins
a child-priority tie. Ordering is deterministic for a given request sequence,
but **equal-priority entries are not guaranteed FIFO order**. Duplicate
priority/payload pairs are separate entries.

## Interface and timing

All transfers occur on the rising edge of `clk`; `rst` is asynchronous,
active high. Supply a reset before issuing requests and release it according
to the integrating clock domain's reset requirements.

| Signals | Meaning |
|---|---|
| `req_valid`, `req_ready` | A command is accepted only when both are high |
| `req_op[1:0]` | 0: push, 1: pop, 2: peek; 3 is invalid |
| `req_priority`, `req_data` | Push entry, captured on acceptance |
| `rsp_valid`, `rsp_ready` | Response remains pending until both are high |
| `rsp_error` | Full push, empty pop/peek, or invalid opcode |
| `rsp_priority`, `rsp_data` | Successful pop/peek entry; zero for push/error |
| `count`, `full`, `empty` | Occupancy, capacity reached, and zero occupancy |

`count` is `max(1, $clog2(DEPTH+1))` bits wide. Successful push/pop changes
occupancy at request acceptance; heap storage may still be settling afterward.
Errors and peek leave occupancy unchanged. Use `req_ready` to authorize a
request, not the occupancy flags. `full` and `empty` report occupancy even
while busy; reset sets count=0, empty=1, full=0.

There is one outstanding command. `req_ready` stays low throughout heap
adjustment and while a response is pending, including its consumption edge.
It rises after that edge; the next request can transfer on the following edge.
A producer must retain valid and request fields until acceptance. Busy-cycle
request pulses are not queued. Response fields are meaningful only when
`rsp_valid=1` and remain stable under backpressure.

Let E be the acceptance edge and H=`floor(log2(DEPTH))`. Peek, errors, and a
pop from a one-entry queue assert `rsp_valid` immediately after E. Successful
push and larger pop responses assert by E+H+1, moving at most one heap level
per cycle and then writing the held entry into its final slot. These bounds
exclude response backpressure. Even an immediate response transfers no
earlier than E+1.

Reset aborts both in-flight commands and pending responses, empties the
queue, and clears response registers. Both handshake outputs are low while
reset is asserted. Stored bits are not reset; occupancy invalidates them.

## Hardware organization

The implementation stores a heap in indexed arrays, with parent `(i-1)/2`
and children `2*i+1`, `2*i+2`. A held-entry register and FSM move an ancestor
or child into a hole, with at most one storage write per clock. Child address
arithmetic retains its carry, including for non-power-of-two depths.

Reads are asynchronous, including parallel child-priority reads. This version
targets small queues using registers or tool-selected distributed storage;
it does **not** promise block-RAM inference or one command per cycle. A
synchronous RAM variant would need explicit read states and revised latency.
No placement/routing or static timing signoff is claimed.

Local Yosys 0.9 `synth_xilinx` baseline (minimum-first mode):

| DEPTH / priority bits / data bits | Estimated LCs | FFs | RAM32X1D primitives |
|---|---:|---:|---:|
| 16 / 8 / 8 | 155 | 46 | 64 |
| 5 / 40 / 40 | 386 | 171 | 320 |

Multiple asynchronous read addresses can replicate distributed memory. These
are synthesis statistics, not device utilization or timing guarantees; inspect
the full resource report rather than treating the LC estimate as total cost.

## Build and verification

Source list: `src/rtl_list.f`, with paths relative to the bench directories.
Alternatively include `src/priority_queue.sv` directly.

```sh
make -C Priority_Queue/tb/sv sim DEPTH=5 MIN_FIRST=0 SEED=19
make -C Priority_Queue/tb/cocotb clean
make -C Priority_Queue/tb/cocotb DEPTH=3 PRIORITY_WIDTH=17
```

SV and cocotb use independent unsorted multiset scoreboards, not heap models.
They check ordering, payload preservation, duplicates, full/empty rejection,
invalid opcodes, busy input changes, backpressure, reset during operations,
and deterministic random traffic. Cocotb also checks continuously asserted
request valid with an always-ready response consumer. Regressions cover both
priority directions, depths 1/2/3/5/16/17, widths through 40 bits, seeds
123/0/19, and wave generation: 30 RTL runs plus six timeout/parameter-rejection
checks. Four configurations run synthesis/no-latch checks and functional
mapped-netlist simulation. Clean bench builds after changing parameters.

## Reusable VIP

[pyUVM](vip/pyuvm/README.md) and [SystemVerilog UVM VIP](vip/uvm/README.md) provide active/passive agents,
pin-based monitors, multiset scoreboards, boundary/random/reset sequences, and
standalone test tops. `make -C Priority_Queue/vip/pyuvm` runs the pyUVM tests.
SV UVM supports actual simulation with Verilator 5.054+ using the shared
`Utils/vip/Makefile`. See its README for the DPI-enabled UVM dependency, then
run `make -C Priority_Queue/vip/uvm sim`. The `lint` target remains available
for compilation checks without simulation.
