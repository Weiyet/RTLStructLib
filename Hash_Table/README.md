# Hash Table

Synthesizable key/value storage using unsigned modulus hashing and bounded
per-bucket chains. Source: `src/hash_table.sv`.

## Parameters

| Parameter | Default | Meaning |
|---|---|---|
| `KEY_WIDTH`, `VALUE_WIDTH` | 32, 32 | Positive key/value widths |
| `TOTAL_INDEX` | 8 | Positive number of buckets |
| `CHAINING_SIZE` | 4 | Positive capacity of each bucket |
| `HASH_ALGORITHM` | "MODULUS" | Only supported hash |
| `COLLISION_METHOD` | "MULTI_STAGE_CHAINING" | Only supported collision method |

All dimensions may be 1; bucket/chain counts need not be powers of two.
Hashing uses every unsigned key bit: `key % TOTAL_INDEX`. Unsupported algorithm
or collision-method strings fail simulation/elaboration. Chains use packed
register arrays, not dynamically allocated linked nodes.

## Request and result protocol

Inputs: `clk`, active-high asynchronous `rst`, `op_en`, `op_sel[1:0]`,
`key_in[KEY_WIDTH-1:0]`, `value_in[VALUE_WIDTH-1:0]`.

Pulse `op_en` for one rising edge while idle. The request key, value, operation
and bucket are captured on that edge; changing inputs during processing does
not change the operation. Busy-cycle pulses are ignored. There is no request
queue or ready output: wait for `op_done` to pulse high and then go low before
presenting the next request. Holding `op_en` high into a later idle cycle
starts another request.

| op_sel | Operation | Result |
|---|---|---|
| 0 | Insert/update | Existing key updates in place, including in a full bucket |
| 1 | Delete | Remove the key, preserving all other entries |
| 2 | Search | Return matching value on `value_out` |
| 3 | Invalid | Complete with `op_error=1`, without changing storage |

New-key insertion into a full bucket and missing-key delete/search complete
with error. Other buckets remain usable. Zero keys and zero values are valid.

`op_done` and `op_error` are one-cycle completion signals. `value_out` is zero
for non-search operations and errors. `collision_count` reports the selected
bucket's **occupancy after the operation**, or zero for an invalid operation.
Result data/count hold until the next accepted request or reset. The count
port width is now `max(1, $clog2(CHAINING_SIZE+1))`; update integration wires
accordingly (default capacity 4 requires **3 bits**, not 2).

## Latency and implementation

The FSM examines one stored key per clock. Completion occurs 1 through
`CHAINING_SIZE+1` cycles after request acceptance, followed by one completion
cleanup cycle. End-of-chain is checked before accessing a slot. Updates do
not increase occupancy; deletion compacts only the suffix and clears the
vacated tail. Reset immediately clears storage/results and aborts an in-flight
request; deassert reset synchronously in the integrating design.

Storage and delete shifting use registers and muxes. Single/power-of-two bucket
hashes use constant wiring/low key bits. Other bucket counts use an unrolled
remainder network with one narrow compare/subtract stage per key bit; its
combinational path grows with key width. No BRAM mapping, alternative hashes, placement,
routing or timing closure is promised.

## Verification

```sh
make -C Hash_Table/tb/sv sim TOTAL_INDEX=3 CHAINING_SIZE=3 KEY_WIDTH=17
make -C Hash_Table/tb/cocotb TOTAL_INDEX=5 KEY_WIDTH=40 VALUE_WIDTH=40
make ci MODULES=hash
```

Use Linux/WSL and `Utils/ci/requirements.txt`; clean builds when changing
parameters. Independent associative-array/dictionary scoreboards verify
collisions, full-bucket updates, first/middle/last deletion, request latching,
busy pulses, zero/wide keys, count width, bounded completion, reset abort,
and seeded traffic. The full suite runs 18 real-RTL cases, four negative
checks, four synthesis builds and four functional mapped-netlist simulations.
Legacy VIP is separate from this verified standalone suite.
