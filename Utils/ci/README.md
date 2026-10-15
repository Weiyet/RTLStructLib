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
make netlist                        # Singly/Doubly mapped-netlist simulations
make checkers                       # Fault/timeout rejection self-checks
make ci                             # Complete hardware verification plan
make test-tools                     # Runner failure-propagation tests
make ci MODULES="singly doubly"      # Select modules
```

Aliases are `systolic`, `list`, `circular`, `singly`, and `doubly`. Other blocks
and UVM/pyUVM VIP are outside this entry point's current scope.

| Suite | Checks with all supported modules selected |
|---|---|
| `check` | 14 real-RTL runs: seven SV and seven cocotb; all three List sum methods |
| `regress` | 189 real-RTL runs and eight forced-timeout rejection checks |
| `synth` | 18 synthesis configurations, including single-node and odd dimensions |
| `netlist` | Six synthesis builds followed by six functional netlist simulations |
| `checkers` | 22 Systolic fixture checks plus eight forced-timeout checks |
| `ci` | Full regressions, 30 checker checks, 18 synthesis builds, six netlist simulations |

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

GitHub Actions runs the five module jobs independently on pull requests,
pushes to `main`, and manual dispatch, retaining artifacts for seven days.
