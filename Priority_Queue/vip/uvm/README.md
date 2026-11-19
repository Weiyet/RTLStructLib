# Priority Queue SystemVerilog UVM VIP

The class-based VIP uses a pre-edge clocking block and drives on falling edges.
Its scoreboard is a passive multiset oracle. Compile-time parameters are shared
by the interface, classes and DUT through `priority_vip_params_pkg`.

## Standalone simulation

Use Linux/WSL, GNU Make, a C++20 compiler, Python 3, GNU `timeout`, and
**Verilator 5.054 or newer**. The default target builds and runs the actual
SV UVM bench and RTL with `--binary --timing --assert --vpi`.
The shared rules are in [`Utils/vip/Makefile`](../../../Utils/vip/Makefile).

Use a UVM library with the Verilator DPI backend. The tested version is
[`verilator/uvm`](https://github.com/verilator/uvm) at commit
`656f20d087370a7c742e00188d20bbf30fa95339` (UVM 2020.3.1):

```sh
git clone https://github.com/verilator/uvm.git /path/to/uvm-verilator
git -C /path/to/uvm-verilator checkout 656f20d087370a7c742e00188d20bbf30fa95339
export UVM_HOME=/path/to/uvm-verilator
export VERILATOR=/path/to/verilator-5.054/bin/verilator
```

From the repository root:

```sh
make -C Priority_Queue/vip/uvm sim
make -C Priority_Queue/vip/uvm run TEST=priority_vip_random_test SEED=19
make -C Priority_Queue/vip/uvm run TEST=priority_vip_reset_test
make -C Priority_Queue/vip/uvm sim DEPTH=5 MIN_FIRST=0 \
    TEST=priority_vip_random_test SIM_BUILD=sim_build/max-first
```

`sim` checks/rebuilds sources and runs; `compile` only builds; `run` reuses the
existing binary. Use `sim` after changing RTL, VIP, parameters or compiler
flags. `TEST` and `SEED` are runtime settings. Keep separate `SIM_BUILD`
directories when retaining several parameter configurations.

`JOBS=2` and `CXX_OPT=-O0` limit build cost by default; both are overridable.
`TB_TIMEOUT_CYCLES` controls the monitor watchdog; `SIM_TIMEOUT=120` limits
wall-clock simulation seconds. Logs go to `SIM_BUILD/compile.log` and
`SIM_BUILD/sim.log`. Nonzero simulator status, timeout, UVM error/fatal reports,
and missing positive completion markers fail Make, including through `tee`.

Override `UVM_INCDIR` or `UVM_DPI` for a different library layout. The stock
Accellera 2020.3.1 DPI source lacks a Verilator HDL backend; use the tested
library above for simulation. DPI remains enabled for UVM regex and command-line
processing. Verilator's two-state simulation does not validate X/Z behavior.

To reuse the shared Makefile in another bench, set `TEST`, `DEFINES`,
`PLUSARGS` and `CHECK_LOG`, then include it. `CHECK_LOG` must name a command
accepting the simulation log path and rejecting incomplete/failed tests.
`TOP` defaults to `tb_top`; `FILELIST` defaults to `files.f`. Paths in the file
list are relative to the invoking bench directory.

## Reuse

Compile `common/priority_vip_params_pkg.sv`, `interface/priority_vip_if.sv`,
and `common/priority_vip_pkg.sv` in that order, with include directories listed
in `files.f`. Connect a `priority_vip_if` instance to your DUT, create
`priority_vip_config`, assign `cfg.vif`, then publish it via
`uvm_config_db#(priority_vip_config)::set(null, "uvm_test_top.env*", "cfg", cfg)`.
Instantiate `priority_vip_env`; start sequences on `env.agent.sequencer`.

Use `cfg.is_active=UVM_PASSIVE` to build only the monitor in the agent. The
scoreboard remains active. Your bench supplies clock/reset and objections.
Observe reset before traffic and hold reset across a rising sampling edge.

Define `PQ_VIP_DEPTH`, `PQ_VIP_PRIORITY_WIDTH`, `PQ_VIP_DATA_WIDTH` and
`PQ_VIP_MIN_FIRST` when compiling to override defaults 16/8/8/1. A compiled
package supports multiple instances with the same parameter set; mixed-width
instances need separately named package/interface specializations.

`priority_vip_seq_item` contains `op`, `priority_value`, `data`, `stalls`,
`reset`, and `abort_after`; the driver returns response fields on the same item.
The supplied base, boundary, random and reset sequence classes can be extended.
Errors, full/empty behavior, priority ties and timing follow the RTL README.

## Validation status

Verilator 5.054 and the pinned UVM library passed all six RTL simulations:

| DEPTH / priority bits / data bits / order | Boundary responses | Random responses | Reset responses |
|---|---:|---:|---:|
| 16 / 8 / 8 / min-first | 202 | 417 | 378 |
| 5 / 40 / 40 / max-first | 70 | 406 | 105 |

Default boundary/reset used seed 123; default random and all max-first tests
used seed 19. All runs reported zero UVM errors/fatals. Reset tests accounted
for 21 and 15 aborted requests respectively. Five negative runs confirmed
nonzero Make status for watchdog timeouts, invalid test names, and a wall-clock
timeout. Old Verilator and missing UVM/DPI dependencies were also rejected.
Compiler warnings remain visible; these are two-state simulation results.

## Verilator check only

```sh
make -C Priority_Queue/vip/uvm lint
```

Use the same environment setup above. Override the queue parameters as needed.
This target checks the UVM package, interface, classes, top and RTL with
`--lint-only --timing --assert`; it does not build or run a simulation binary.
Both lint and simulation retain warnings through `-Wno-fatal`, while compiler
errors still fail. No unsupported-feature bypass flags are used.
The log is `SIM_BUILD/lint.log`.
