# Table SystemVerilog UVM VIP

## Run with Verilator

Use Linux/WSL, GNU Make, Python 3, a C++20 compiler, GNU `timeout`, an SMT
solver (`z3` on `PATH`) for constrained randomization, and Verilator 5.054 or newer. Set
`VERILATOR` and `UVM_HOME` using the tested DPI-enabled UVM setup in the
[Priority Queue guide](../../../Priority_Queue/vip/uvm/README.md#standalone-simulation).

From the repository root:

```sh
make -C Table/vip/uvm sim TEST=simple_test SEED=123
make -C Table/vip/uvm run TEST=boundary_test SEED=19
```

The local Makefile includes `../../../Utils/vip/Makefile`. `compile` builds,
`sim` builds and runs, and `run` reuses the executable. Rebuild after source
changes. `lint` checks elaboration without running the DUT. For smaller C++
compilation units, pass `VERILATOR_FLAGS="--output-groups 16"`.

Logs are `SIM_BUILD/compile.log` and `SIM_BUILD/sim.log` (default `sim_build`).
`JOBS`, `SIM_TIMEOUT` (wall-clock seconds), and `TB_TIMEOUT_CYCLES` are
configurable. Simulation failure, watchdog expiry, UVM errors/fatals, and
missing nonzero scoreboard completion all fail Make.

## Tests and checking

Registered scenarios: `simple_test`, `random_test`, `parallel_access_test`, `boundary_test`.
`boundary_test` includes directed edge cases and reset during the scenario;
`SEED` controls randomized stimulus.

All indices, simultaneous ports, highest write-port priority on collisions, write-first read forwarding, disabled-read output retention, and reset recovery. The model checks every clock, including idle cycles.

Standalone configuration: **TABLE_SIZE=32, 8-bit data, INPUT_RATE=2, OUTPUT_RATE=2**. The interface widths, DUT parameters
in `sim/tb_top.sv`, and configuration in `sim/tests/table_vip_base_test.sv`
must agree when adapting the bench. Changing the class configuration alone
does not resize the interface or RTL. Verilator simulation is two-state;
these tests do not check X/Z propagation.

## Reuse

Use the source order and include directories in `files.f`. Connect
`table_vip_if` to the DUT, publish it under `table_vip_vif`, and publish a
matching `table_vip_config` under `table_vip_cfg` through `uvm_config_db`.
Instantiate `table_vip_env` and start sequences on `env.get_sequencer()`.
The enclosing bench supplies clocks, reset, and UVM objections. See the
[block README](../../README.md) for the hardware contract.

## Validation

Verilator 5.054 with the pinned UVM library passed 8 RTL simulations
(all scenarios above, seeds 123 and 19), checking 401 monitored
transactions/edges in total with zero UVM errors or fatals. Empty-test,
unknown-test, and forced-watchdog runs each returned failure as expected.
These results cover the standalone configuration above.
