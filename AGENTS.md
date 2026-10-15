# Repository Guidelines

## Project Structure & Module Organization

RTLStructLib contains parameterized, synthesizable SystemVerilog data structures. Each block has its own directory, such as `FIFO/`, `LIFO/`, `Table/`, `Hash_Table/`, or `Systolic_Array/`.

- `src/`: RTL and source lists, usually `rtl_list.f`; check the actual filename before integration.
- `tb/sv/` and `tb/cocotb/`: standalone SystemVerilog and Python testbenches.
- `vip/uvm/` and `vip/pyuvm/`: verification components, sequences, scoreboards, and tests where available. Some VIP is still under development.
- `FIFO/vip/cpp/`: Verilator C++ testbench.
- `Utils/tb/`: shared benches and result checks; `Utils/ci/`: regression runner; `assets/`: documentation images.

Read the affected block's `README.md` for interfaces, parameters, and timing behavior.

## Build, Test, and Development Commands

Use a Linux/WSL environment with GNU Make and shell utilities. Install Icarus Verilog for simulation, Yosys for synthesis, and GTKWave for waveform inspection; Python benches require `cocotb`, with `cocotb-bus` or `pyuvm` as applicable.

- `make check`: default SV/cocotb checks for Systolic, List, and three Linked Lists.
- `make ci MODULES="singly doubly"`: full regressions, synthesis, and supported netlist checks; omit `MODULES` for all five blocks.
- `make test-tools`: check runner failure handling. See `Utils/ci/README.md` for setup and reports.
- `make -C FIFO/tb/sv sim SEED=123`: compile and simulate the FIFO.
- `make -C FIFO/tb/cocotb`: run standalone cocotb tests.
- `make -C FIFO/vip/pyuvm`: run the Python UVM bench.
- `make -C FIFO/vip/cpp run`: build and run the C++17 bench with Verilator.

Replace `FIFO` where supported. Clean bench builds after changing parameters.

## Coding Style & Naming Conventions

Follow neighboring files; use four-space indentation in SystemVerilog and Python, and tabs for Makefile recipes. Use snake_case for RTL signals/modules and Python functions, uppercase for parameters such as `DATA_WIDTH`, and existing VIP prefixes such as `fifo_vip_`. Keep RTL synthesizable and update source lists when adding dependencies. No repository-wide formatter or linter is configured.

## Testing Guidelines

Extend `tb.sv`, cocotb `tb.py`, or VIP tests named `<prefix>_vip_<scenario>_test.py`/`.sv`. Check reset, boundary conditions, simultaneous operations, and relevant parameter combinations against assertions or scoreboards. No numeric coverage threshold is defined. Record commands, parameters, seeds, and results; inspect simulation logs for failures.

## Commit & Pull Request Guidelines

History uses short descriptive subjects such as `add pyUVM VIP`; no enforced commit prefix scheme is evident. Use an imperative subject identifying the affected block. PRs should explain behavior changes, link relevant issues, list verification results, and update interface documentation. Include waveforms when they clarify timing changes. Keep generated simulation outputs and build directories out of commits.
