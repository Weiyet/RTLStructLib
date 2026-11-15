# Multi-port table

A single-clock register file with independent packed write/read ports and
registered read data. Source: `src/table.sv`, top module `table_top`.

## Parameters and packing

`TABLE_SIZE=32`, `DATA_WIDTH=8`, `INPUT_RATE=2`, and `OUTPUT_RATE=2`
must all be positive. Address width is `max(1, $clog2(TABLE_SIZE))`;
a single-entry table therefore uses one address bit.

Port 0 occupies the least significant slice: write address
`index_wr[p*INDEX_WIDTH +: INDEX_WIDTH]`, write data
`data_wr[p*DATA_WIDTH +: DATA_WIDTH]`, and read output
`data_rd[p*DATA_WIDTH +: DATA_WIDTH]`. Each writer has its own `wr_en[p]`;
one `rd_en` enables all read ports.

## Defined clock-edge behavior

- Enabled, in-range writes update storage at the rising edge.
- When writers address the same entry, the highest numbered enabled port wins.
- An enabled read of an entry written on that edge returns the winning **new**
  value. Explicit forwarding implements this write-first behavior.
- Out-of-range writes are ignored; enabled out-of-range reads return zero.
- When `rd_en=0`, all read outputs hold their previous values, even during writes.
- Active-high asynchronous `rst` clears storage and outputs. Reset overrides
  all operations; deassert it synchronously in the integrating design.

Clocked storage and output assignments are nonblocking; each process uses
separate loop indices. This removes the original simulator scheduling race.
Storage is implemented as resettable registers with forwarding muxes; area and
read-path delay grow with table size and port count. BRAM inference is not
promised for this multi-write-port interface.

## Verification

```sh
make -C Table/tb/sv sim TABLE_SIZE=3 INPUT_RATE=3 DATA_WIDTH=17
make -C Table/tb/cocotb TABLE_SIZE=1 DATA_WIDTH=1 INPUT_RATE=1 OUTPUT_RATE=1
make ci MODULES=table
```

Run in Linux/WSL with `Utils/ci/requirements.txt`; clean builds after parameter
changes. SV and cocotb scoreboards check write priority, same-edge forwarding,
independent ports, invalid indices, disabled-read holding, asynchronous reset,
wide data, and seeded random traffic. The full suite contains 18 real-RTL
runs, two forced-timeout checks, four synthesis builds, and four functional
mapped-netlist simulations. Use `SEED=123` for reproducibility and `WAVES=1`
for waveforms. Legacy UVM/pyUVM VIP is outside this verified suite.