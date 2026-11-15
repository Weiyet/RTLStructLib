# RTL regression and CI

Run from the repository root in Linux/WSL with GNU Make, Python 3.10,
Icarus Verilog and Yosys. Install the tested Python bindings with
`python3 -m pip install -r Utils/ci/requirements.txt` (prefer a virtual environment).
The local baseline is Icarus 11.0, Yosys 0.9 and cocotb 1.8.1; GitHub Actions
uses the Ubuntu 22.04 packages and the pinned Python requirements.

```sh
make check                          # Default SV and cocotb benches
make regress                        # Existing complete parameter/seed suites
make synth                          # Xilinx synthesis and structural checks
make netlist                        # FIFO/LIFO/Singly/Doubly mapped-netlist simulations
make checkers                       # Fault/timeout rejection self-checks
make ci                             # Complete hardware verification plan
make test-tools                     # Runner failure-propagation tests
make ci MODULES="singly doubly"      # Select modules
```

Aliases are `systolic`, `list`, `circular`, `singly`, `doubly`, `lifo`, and `fifo`. Other blocks
and UVM/pyUVM VIP are outside this entry point's current scope.

| Suite | Checks with all supported modules selected |
|---|---|
| `check` | 18 real-RTL runs: nine SV and nine cocotb; all three List sum methods |
| `regress` | 262 real-RTL runs and 16 timeout/parameter rejection checks |
| `synth` | 27 synthesis configurations, including single-entry and odd dimensions |
| `netlist` | 14 synthesis builds followed by 14 functional netlist simulations |
| `checkers` | 22 Systolic fixture checks plus 12 forced-timeout checks |
| `ci` | Full regressions, 38 checker checks, 27 synthesis builds, 14 netlist simulations |

`SEED=123` controls direct bench/netlist runs. Full regressions retain their
documented fixed seed matrices. `JOBS=1` is the default because existing
regression scripts already run parallel jobs. Increase cautiously on larger hosts.
Use `python3 Utils/ci/verify.py --suite ci --list` to inspect commands.

Logs, default-bench XML, mapped netlists and synthesis logs go under
`sim_build/verification/`; override with `ARTIFACT_DIR=/absolute/path`.
`summary.json` records commands, tool versions, commit, timings and separate
hardware/checker counts; `summary.md` is also added to the Actions job summary.
Existing full runners use temporary build directories; their retained outer
logs contain per-case results, but their temporary waveforms are removed.

Missing/empty/failed/skipped XML, absent SV completion markers, synthesis
errors and host timeouts fail the command. Stale output reports are removed
before execution. Independent checks continue so failure logs remain available.
Synthesis rejects inferred latches and structural errors. Netlist simulations
use Yosys's Xilinx cell models; they do not include delays, placement/routing
or static timing analysis. Checker fixtures are never counted as real RTL.

GitHub Actions runs the seven module jobs independently on pull requests,
pushes to `main`, and manual dispatch, retaining artifacts for seven days.
