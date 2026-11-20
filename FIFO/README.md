# FIFO queue

Synthesizable SystemVerilog FIFO with full capacity, synchronous or asynchronous
clocks, and registered or gated combinational read output. Source: `src/fifo.sv`.

## Parameters

| Parameter | Default | Contract |
|---|---|---|
| `DEPTH` | **16** | ASYNC=1: power of two, at least 2; ASYNC=0: any positive depth |
| `DATA_WIDTH` | 8 | Positive bit width |
| `ASYNC` | 1 | 1: independent clocks; 0: connect both clock ports to the same clock |
| `RD_BUFFER` | 1 | 1: registered output; 0: gated combinational output |

The default depth changed from 12 to 16 to satisfy the asynchronous Gray-ring
contract. Use `ASYNC=0, DEPTH=12` for a synchronous 12-entry FIFO. Unsupported
parameters fail simulation/elaboration.

## Interface and acceptance

Inputs: `wr_clk`, `rd_clk`, active-high asynchronous `rst`, `wr_en`,
`rd_en`, `data_wr[DATA_WIDTH-1:0]`. Outputs: `fifo_full`, `fifo_empty`,
`data_rd[DATA_WIDTH-1:0]`.

A write is accepted at a write rising edge when `wr_en && !fifo_full`.
A read is accepted at a read rising edge when `rd_en && !fifo_empty`.
Use flags **before** the edge. Rejected operations do not advance pointers.
There is no empty bypass or full replacement: simultaneous operations are
accepted independently according to their pre-edge flags.

With `RD_BUFFER=1`, accepted reads update the output after the edge; otherwise
the last value holds. With `RD_BUFFER=0`, the current head is visible only while
`rd_en && !fifo_empty`; sample it before the read edge. The output then advances
to the next head, or zero when disabled/empty. This mode is not always-on FWFT.

## Reset and clock-domain crossing

Reset discards all entries and clears the registered output, without resetting
the memory array. Both flags assert during reset: full blocks writes, empty
blocks reads. Two local clock edges release each domain; operations begin on
the following edge. A stopped clock keeps its domain blocked. Apply reset to
the entire FIFO, not to one domain independently.

Synchronous mode uses an occupancy counter and explicit address wrap.
Asynchronous mode uses address-plus-wrap binary pointers, registered Gray
encodings, and two `ASYNC_REG` stages in each direction. Only the second stage
drives local full/empty decisions. Flags can conservatively remain asserted
until the remote pointer propagates through two synchronizer stages and the
local flag register. Source Gray pointers change at most one bit per accepted
operation; destination samples may skip source states.

### Physical integration

Simulation checks ordering and Gray transitions, not metastability or routed
timing. Preserve synchronizer placement attributes, constrain both clocks,
and bound Gray-bus delay/skew to the first synchronizer stage using constraints
from the integrating project. Inspect synthesized register names and clock
periods when defining these paths.

Do not override those maximum-delay paths with blanket asynchronous clock
groups or false paths. Keep the first-to-second synchronizer paths timed
normally. Review reset recovery/removal, data-memory crossings, CDC reports,
`report_bus_skew`, and timing reports in the integrating design.
No Vivado CDC analysis, place/route or STA sign-off is included here.

## Verification

```sh
make -C FIFO/tb/sv sim ASYNC=0 DEPTH=3 RD_BUFFER=0
make -C FIFO/tb/cocotb DEPTH=4 WR_HALF=5 RD_HALF=2
```

Use Linux/WSL with `cocotb==1.8.1` and `find-libpython==0.3.1`. Clean builds when changing
parameters. Independent SV and Python queue scoreboards cover fill/drain,
overflow/underflow, repeated wrap, simultaneous operations, reset while full,
unrelated/equal clock rates, stopped clocks, both output modes, wide data, and
seeded traffic. The matrix contains 42 real-RTL runs, six negative checks
(timeouts and illegal parameters), four synthesis builds and four functional
mapped-netlist simulations. `WAVES=1` enables VCD/FST output.

The [SV UVM bench](vip/uvm/README.md) has a separate Verilator regression.
Legacy pyUVM and C++ VIP are not part of the standalone suite above; integrations
must honor reset backpressure and asynchronous flag latency.
