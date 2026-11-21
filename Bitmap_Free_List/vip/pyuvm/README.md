# Bitmap Free List pyUVM VIP

## Run

Use Linux/WSL, Icarus Verilog, Python 3.10, and the pinned dependencies:

```sh
python3 -m pip install -r Bitmap_Free_List/vip/pyuvm/requirements.txt
make -C Bitmap_Free_List/vip/pyuvm CAPACITY=5 SEED=123
make -C Bitmap_Free_List/vip/pyuvm CAPACITY=33 SEED=19 SIM_BUILD=sim_build/c33
```

The Makefile includes `../../../Utils/vip/pyuvm/Makefile`. It adds the repository
root to `PYTHONPATH`, runs cocotb, and rejects failed, skipped, or empty XML
results. Use separate `SIM_BUILD` directories or clean before changing
`CAPACITY`. `TB_TIMEOUT_CYCLES` controls the monitor watchdog; `WAVES=1` enables
waveforms. `TESTCASE=bitmap_vip_random_test` selects one scenario.

`tb_bitmap.py` registers four tests: `bitmap_vip_boundary_test`,
`bitmap_vip_random_test`, `bitmap_vip_reset_test`, and `bitmap_vip_passive_test`.
They cover exhaustion, minimum-ID selection, double/invalid release, same-cycle
reuse, reset priority, 600 seeded random cycles, and passive monitoring. All
scenarios end with every ID released. The Python ownership-set scoreboard
checks all output fields from sampled pins, including idle and reset cycles.

## Reuse

Import through `Bitmap_Free_List.vip.pyuvm` to keep package names distinct from
other VIPs. `common/` holds configuration and sequence items; `agent/` contains
driver, monitor, and agent; `env/` contains environment and scoreboard;
`sequences/` and `tests/` hold the scenario implementations.

```python
from pyuvm import ConfigDB
from Bitmap_Free_List.vip.pyuvm.common.bitmap_vip_config import BitmapVipConfig
from Bitmap_Free_List.vip.pyuvm.env.bitmap_vip_env import BitmapVipEnv

cfg = BitmapVipConfig.from_dut(dut, active=True, seed=123)
ConfigDB().set(None, "*", "bitmap_vip_cfg", cfg)
# Inside a test's build_phase:
self.env = BitmapVipEnv("env", self)
```

If simulator parameters are hidden, construct `BitmapVipConfig` explicitly
with matching `capacity` and `id_width`. Start `BitmapVipSequence(name, cfg,
scenario)` on `env.get_sequencer()`; scenarios are `boundary`, `random`, and
`reset`. Items provide `allocate`, `release`, `ident`, `reset`, and `response`.

Active sequences control reset. For passive integration set `active=False`
before environment creation; the agent creates only its monitor, and external
logic supplies requests/reset. The enclosing test supplies clock and objections.
Keep ConfigDB entries when invoking `uvm_root().run_test(...,
keep_singletons=True)`, as demonstrated in `tb_bitmap.py`.

Requests are driven on falling edges, responses are read after RTL updates,
and requests clear 1 ns after that rising edge. The supplied period is 10 ns;
adapt timing for faster clocks. A sampled reset is required before traffic.
See the [RTL contract](../../README.md) for release-before-allocation behavior.

## Validation

All 48 scenarios passed on Icarus with cocotb 1.8.1 / pyUVM 3.0.0: four
scenarios, capacities 1/2/3/5/16/33, and seeds 123/19. Forced-watchdog and
empty-test runs failed as expected. A local RTL mutant incrementing free_count
incorrectly was rejected by the pin-sampled scoreboard. Regression runners,
mutants, logs, and simulator outputs remain local-only.
