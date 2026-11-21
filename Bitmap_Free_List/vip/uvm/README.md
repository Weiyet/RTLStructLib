# Bitmap Free List SystemVerilog UVM VIP

## Run

Use Linux/WSL, GNU Make, Python 3, a C++20 compiler, GNU `timeout`, and
Verilator 5.054 or newer. Set `VERILATOR` and `UVM_HOME` following the
[pinned DPI-enabled UVM setup](../../../Priority_Queue/vip/uvm/README.md#standalone-simulation).
The provided sequences use `$urandom`; they do not require an SMT solver.

```sh
make -C Bitmap_Free_List/vip/uvm sim CAPACITY=5 TEST=bitmap_vip_boundary_test
make -C Bitmap_Free_List/vip/uvm run TEST=bitmap_vip_random_test SEED=19
```

The Makefile includes `../../../Utils/vip/Makefile`. `sim` rebuilds and runs;
`compile` builds only; `run` reuses the binary; `lint` checks elaboration only.
`CAPACITY` defaults to 16 and controls the parameter package, interface, DUT,
and model together. Recompile after changing it; use separate `SIM_BUILD`
paths for configurations. One compiled package supports one capacity; mixed
capacities need separately named package/interface specializations. `SEED` and
`TEST` are runtime settings.
`VERILATOR_FLAGS="--output-groups 16"` splits C++ compilation into smaller units.

Logs are `SIM_BUILD/compile.log` and `SIM_BUILD/sim.log`. `TB_TIMEOUT_CYCLES`
controls the monitor watchdog; `SIM_TIMEOUT` limits wall-clock runtime. The
shared log checker rejects UVM errors/fatals and missing nonzero completion.

## Scenarios and model

- `bitmap_vip_boundary_test`: lowest-ID selection, exhaustion, duplicate and
  invalid releases, same-cycle reuse, and a final full allocation/release sweep.
- `bitmap_vip_random_test`: 600 seeded request cycles with periodic resets.
- `bitmap_vip_reset_test`: reset while slots are owned and requests are asserted.
- `bitmap_vip_passive_test`: external stimulus with no agent driver/sequencer.
- `bitmap_vip_empty_test`: intentional failure, checking empty-run rejection.

The monitor captures requests before the rising edge and responses 1 ns after
it. The independent scoreboard stores owned IDs in an associative set, applies
release-before-allocation, and checks every response, count, and flag, including
idle and reset cycles. Requests are driven on falling edges; driver completion
is 2 ns after the rising edge. The supplied clock period is 10 ns. Adapt these
settling intervals for faster integration clocks. Verilator is two-state.

## Reuse

Follow `files.f` for compilation order. Import `bitmap_vip_pkg`, connect
`bitmap_vip_if`, and create `bitmap_vip_config` with `cfg.vif` set. Publish it
under `cfg` through `uvm_config_db` to your environment and children, then create
`bitmap_vip_env`. Start `bitmap_vip_sequence` on `env.agent.sequencer` and select
its `scenario` (`boundary`, `random`, or `reset`). The sequence owns reset in
active mode. The enclosing test supplies clocks and objections.

Set `cfg.is_active=UVM_PASSIVE` before building the environment to observe
externally driven traffic. Observe a synchronous reset before traffic.
`bitmap_vip_seq_item` contains request fields `rst`, `alloc_req`, `free_req`,
`free_id` and response fields matching the RTL. The scoreboard consumes only
monitor samples, never driver transactions. See the [RTL contract](../../README.md).

## Validation

Verilator 5.054 with the pinned DPI-enabled UVM library passed 24 RTL
simulations: capacities 1/5/16, seeds 123/19, and all four functional scenarios.
Every run reported zero UVM errors/fatals. Empty-test, unknown-test, and
forced-watchdog runs failed as expected for each capacity (nine checks).
Regression runners, build artifacts, and logs remain local-only.
