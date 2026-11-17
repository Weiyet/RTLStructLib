# Priority Queue pyUVM VIP

Use Python 3.10, Icarus Verilog 11, cocotb 1.8.1 and pyUVM 3.0.0. Dependencies
are pinned to match the repository simulator environment.

```sh
# From repository root:
python3 -m pip install -r Priority_Queue/vip/pyuvm/requirements.txt
make -C Priority_Queue/vip/pyuvm
make -C Priority_Queue/vip/pyuvm clean
make -C Priority_Queue/vip/pyuvm DEPTH=3 MIN_FIRST=0 PRIORITY_WIDTH=17 DATA_WIDTH=40 SEED=19
```

`tb_priority.py` starts the clock, sets `PriorityVipConfig` in `ConfigDB`, and
runs four tests. `priority_queue_vip/` is a namespaced Python package, avoiding
collisions with the installed `pyuvm` package or generic `tests` packages.

- `common.py`: `PriorityVipConfig`, `PriorityVipItem`.
- `agent.py`: driver, pin monitor and active/passive agent; uses a standard pyUVM sequencer.
- `scoreboard.py`, `env.py`: multiset model, protocol checking and TLM connections.
- `sequences.py`: boundary, random, and reset-during-operation sequences.
- `tests.py`: corresponding UVM tests.

## Integration

Put `Priority_Queue/vip/pyuvm` on `PYTHONPATH`. Create the configuration with
`PriorityVipConfig.from_dut(dut)` or explicitly provide parameters if your
simulator does not expose them. Set it before building `PriorityVipEnv`:

```python
cfg = PriorityVipConfig.from_dut(dut, active=True, seed=123)
ConfigDB().set(None, "*", "priority_vip_cfg", cfg)
# Inside your uvm_test.build_phase:
self.env = PriorityVipEnv("env", self)
```

In a sequence body, use `await self.start_item(item)` / `await self.finish_item(item)`
with `PriorityVipItem(op=0, priority=3, data=42, stalls=2)`. Operations are
0=push, 1=pop, 2=peek, 3=invalid. The driver sets `item.response` to
`(error, priority, data)` after completion. `reset=True` issues reset;
`abort_after=N` resets N cycles after the first falling edge following acceptance,
with response ready held low; `item.aborted` records cancellation.

Set `cfg.active=False` for passive monitoring; do not start sequences on that
agent. The environment still checks observed traffic. For several instances,
use separate ConfigDB instance paths instead of the example's wildcard.

Select a test with `TESTCASE=priority_vip_boundary_test`,
`priority_vip_random_test`, `priority_vip_reset_test`, or `priority_vip_passive_test`.
The passive test uses external stimulus and X-valued unused request fields.
Set `WAVES=1` for FST
output. `TB_TIMEOUT_CYCLES` is the total monitored-clock watchdog; the scoreboard
also enforces the heap response bound independently of consumer backpressure.
Clean builds after parameter changes. Failures propagate through XML checks,
even when the simulator itself exits zero.
