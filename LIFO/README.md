# LIFO (Stack)

A single-clock, synthesizable SystemVerilog stack with a registered read output
and a simultaneous read/write bypass. Source: `src/lifo.sv`.

## Parameters and interface

| Parameter | Default | Supported values |
|---|---|---|
| `DEPTH` | 12 | Positive integer, including 1 and non-powers of two |
| `DATA_WIDTH` | 8 | Positive integer |

Inputs are `clk`, active-high asynchronous `rst`, `wr_en`, `rd_en`, and
`data_wr[DATA_WIDTH-1:0]`. Outputs are `lifo_full`, `lifo_empty`, and
`data_rd[DATA_WIDTH-1:0]`.

## Clock-edge behavior

| wr_en | rd_en | Action at the rising edge |
|---|---|---|
| 0 | 0 | Hold stack and output |
| 1 | 0 | Push if not full; otherwise ignore |
| 0 | 1 | Pop into `data_rd` if not empty; otherwise hold output |
| 1 | 1 | Register `data_wr` into `data_rd`; leave stack unchanged |

Bypass works at every occupancy, including full and empty. It does not replace
the stored top entry. Both pop and bypass outputs become valid after the
sampling edge; bypass is not combinational. Push and idle cycles hold the last
read output.

The occupancy register represents **0 through DEPTH**, so power-of-two stacks
retain every entry. Flags decode occupancy and reflect the state after each
edge. Reset immediately clears occupancy, stored entries and output. Deassert
reset synchronously to `clk` in the integrating design.

Storage uses resettable registers; this implementation does not promise BRAM
inference. There is no independent read clock or ready/valid interface.

## Verification

Run in Linux/WSL with Icarus, Yosys, GNU Make, `cocotb==1.8.1`
and `find-libpython==0.3.1`:

```sh
make -C LIFO/tb/sv sim DEPTH=8 DATA_WIDTH=17 SEED=123
make -C LIFO/tb/cocotb DEPTH=1 DATA_WIDTH=1
make -C LIFO/tb/sv netlist_sim
```

Clean the selected build directory before reusing it with different parameters.
Both benches compare real DUT ports with independent stack scoreboards.
Coverage includes empty/full rejection, complete drains, repeated wraps, bypass
at every occupancy, asynchronous reset, output holding, every data bit, and
seeded random traffic. The full suite runs 31 RTL configurations/seeds (six
cocotb scenarios per run), two forced-timeout rejection checks, five synthesis
configurations and four functional mapped-netlist simulations.

Set `WAVES=1` for SV VCD or cocotb FST output. Failures return nonzero through
Make, and cocotb XML must contain passing, non-skipped tests. Existing UVM and
pyUVM VIP are separate from this verified standalone suite.
