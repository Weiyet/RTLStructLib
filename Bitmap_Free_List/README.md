# Bitmap Free List

A synthesizable slot-ID allocator for descriptor pools, linked-list nodes,
and bounded storage tables. It stores one free bit per slot and allocates the
lowest available ID. No payload memory is included.

## Parameters and ports

`CAPACITY` defaults to 16 and must be positive. Valid IDs are `0..CAPACITY-1`.
ID width is `max(1, $clog2(CAPACITY))`; count width is
`max(1, $clog2(CAPACITY+1))`. Non-power-of-two capacities are supported.

| Port | Direction | Meaning |
|---|---|---|
| `clk`, `rst` | Input | Rising-edge clock; synchronous active-high reset |
| `alloc_req` | Input | Request one slot |
| `free_req`, `free_id` | Input | Request release of an owned slot |
| `alloc_valid`, `alloc_id` | Output | Successful allocation and selected ID |
| `alloc_error` | Output | Allocation requested with no available slot |
| `free_valid` | Output | Successful release |
| `free_error` | Output | Release requested for an invalid or already-free ID |
| `free_count` | Output | Number of available slots after the operation |
| `exhausted`, `all_free` | Output | Count equals zero or CAPACITY |

## Cycle contract

Inputs are sampled at each rising edge. Registered responses and state become
visible after that edge. Throughput is one allocation and one release per
clock, with no ready/backpressure handshake. A request held high issues a new
operation every cycle; the consumer must accept every response.

Release validity is determined from ownership **before** the edge. A valid
release is applied first, then allocation selects the lowest free ID from the
updated pool. Thus an exhausted pool can release and reallocate the same ID
in one cycle. If another lower ID is free, that lower ID is allocated instead.
An invalid release does not prevent an otherwise valid allocation.

For example, with CAPACITY=3 and every ID owned, `free_req=1, free_id=2,
alloc_req=1` returns both valid responses, allocates ID 2, and leaves
`free_count=0`. Releasing ID 2 when it was already free instead reports
`free_error=1`; allocation may still claim it.

Each response-valid/error bit is zero when its request is absent. `alloc_id`
is zero unless `alloc_valid=1`. Errors leave the corresponding operation's
state unchanged. Reset overrides requests, restores every slot to free, clears
all response bits/ID, and must be sampled before normal use. Reset revokes all
previous ownership; clients must discard outstanding IDs.

## Architecture and integration

Compile `src/bitmap_free_list.sv` (`src/rtl_list.f` is relative to `src/`).
The bitmap and free count use flip-flops; combinational release forwarding
feeds a lowest-ID priority encoder. Storage grows linearly with CAPACITY;
the encoder and variable-ID release decode can limit clock frequency at large
capacities. No post-route timing or area target is claimed.

## Verification

Both benches use the repository's shared Makefile includes (Icarus by default).
Use Python 3 with `cocotb==1.8.1` for the Python bench. From Linux/WSL:

```sh
make -C Bitmap_Free_List/tb/sv sim CAPACITY=5 SEED=123
make -C Bitmap_Free_List/tb/cocotb CAPACITY=33 SEED=19
make -C Bitmap_Free_List/tb/sv netlist_sim CAPACITY=5
```

The SV bench tracks owned IDs; cocotb uses a Python set and also checks that
outputs hold between rising edges. Directed tests cover exhaustion, lowest-ID
selection, duplicate and out-of-range releases, simultaneous operations,
reset priority, and recovery. Each run adds 2,000 randomized cycles and a
final full allocation/release sweep. `TB_TIMEOUT_CYCLES` fails stalled tests;
`WAVES=1` enables waveforms. Use separate `SIM_BUILD` paths or clean cocotb
builds when changing parameters. Reusable [SV UVM](vip/uvm/README.md) and
[pyUVM](vip/pyuvm/README.md) environments provide separate VIP regressions.

To run the same SV scoreboard with Verilator, from the repository root:

```sh
verilator --binary --timing --assert -Wno-fatal --top-module tb \
    -GCAPACITY=5 --Mdir sim_build/free_list_verilator \
    Bitmap_Free_List/tb/sv/tb.sv Bitmap_Free_List/src/bitmap_free_list.sv
./sim_build/free_list_verilator/Vtb +SEED=19
```

### Validated configurations

| Check | CAPACITY | Seeds | Result |
|---|---|---|---|
| Icarus SV scoreboard | 1, 2, 3, 5, 16, 33 | 123, 19 | 12 passed |
| cocotb / Icarus | 1, 2, 3, 5, 16, 33 | 123, 19 | 12 passed |
| Verilator 5.054 SV scoreboard | 1, 5, 33 | 123, 19 | 6 passed |
| Yosys Xilinx synthesis + mapped simulation | 1, 5, 33 | 123 | 3 passed |

Synthesis includes structural checks and rejects inferred latches. CAPACITY=0,
the SV watchdog, and the cocotb watchdog each returned failure as expected
(three negative checks). These are functional checks, not timing sign-off.
