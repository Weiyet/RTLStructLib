# Priority Queue SystemVerilog UVM VIP

The class-based VIP uses a pre-edge clocking block and drives on falling edges.
Its scoreboard is a passive multiset oracle. Compile-time parameters are shared
by the interface, classes and DUT through `priority_vip_params_pkg`.

## Standalone simulation

The Makefile provides a **Questa command template**, requiring a UVM-capable
installation and its precompiled UVM library. It has not been run locally;
Icarus is used only for the separate pyUVM environment.

```sh
make -C Priority_Queue/vip/uvm UVM_HOME=/path/to/uvm \
    UVM_LIB=uvm TEST=priority_vip_boundary_test
make -C Priority_Queue/vip/uvm UVM_HOME=/path/to/uvm \
    TEST=priority_vip_random_test DEPTH=5 MIN_FIRST=0 SEED=19
make -C Priority_Queue/vip/uvm UVM_HOME=/path/to/uvm \
    TEST=priority_vip_reset_test
```

Override `UVM_INCDIR` if macros are not in `$UVM_HOME/src`, and `UVM_LIB` to
match the installed library. The source and compiled library versions must
match. Each invocation recompiles with the requested parameters. Simulator
errors, UVM error/fatal reports, and missing completion markers fail the Make
target. `TB_TIMEOUT_CYCLES` controls the monitor's total-cycle watchdog.

For another simulator, compile its UVM package first, add the UVM macro include
directory, then compile `files.f` from this directory. Elaborate `tb_top` with
`+UVM_TESTNAME=priority_vip_boundary_test` (or random/reset test). Use that
simulator's seed option. `sim/check_uvm_log.py` validates the completion log.

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

Local checks passed four parameter configurations with pyslang 11.0.0 and
Verilator 5.054 against official Accellera UVM 2020.3.1.
**No SV UVM simulation result is claimed.** The executable, parameter-regressed
verification environment in this repository is currently the pyUVM variant.

## Verilator check only

```sh
make -C Priority_Queue/vip/uvm lint UVM_HOME=/path/to/uvm-core \
    VERILATOR=/path/to/verilator-5.054/bin/verilator
```

Run this from the repository root. Override `DEPTH`, `PRIORITY_WIDTH`,
`DATA_WIDTH` and `MIN_FIRST` to check another configuration. The target uses
`--lint-only --timing` with the
actual UVM package, interface, classes, top and RTL. It does not build
a testbench executable or run UVM phases. `-Wno-fatal` retains warnings without
making them fatal; errors and unsupported syntax still fail. No black-box or
unsupported-feature bypass flags are used. This is not a warning-free claim.

Use Verilator 5.054 or newer; 5.024 fails inside the official UVM library.
The validated UVM source commit is `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`.
Inspect `Priority_Queue/vip/uvm/sim_build/lint.log`; override `SIM_BUILD` to
retain outputs elsewhere. The lint target does not build a simulation binary.
