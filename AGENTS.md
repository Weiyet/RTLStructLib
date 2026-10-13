# Repository Guidelines

## Project Structure & Module Organization

RTLStructLib contains parameterized, synthesizable SystemVerilog data structures. Each block has its own directory, such as `FIFO/`, `LIFO/`, `Table/`, `Hash_Table/`, or `Systolic_Array/`.

- `src/`: RTL and source lists, usually `rtl_list.f`; check the actual filename before integration.
- `tb/sv/` and `tb/cocotb/`: standalone SystemVerilog and Python testbenches.
- `vip/uvm/` and `vip/pyuvm/`: verification components, sequences, scoreboards, and tests where available. Some VIP is still under development.
- `FIFO/vip/cpp/`: Verilator C++ testbench.
- `Utils/tb/`: reusable Makefile templates; `assets/`: documentation images.

Read the affected block's `README.md` for interfaces, parameters, and timing behavior.

## Build, Test, and Development Commands

Use a Linux/WSL environment with GNU Make and shell utilities. Install Icarus Verilog for simulation, Yosys for synthesis, and GTKWave for waveform inspection; Python benches require `cocotb`, with `cocotb-bus` or `pyuvm` as applicable.

- `make -C FIFO/tb/sv sim SEED=123`: compile and simulate the FIFO with a reproducible seed.
- `make -C FIFO/tb/sv synth`: generate a Xilinx-targeted netlist with Yosys.
- `make -C FIFO/tb/cocotb`: run standalone cocotb tests.
- `make -C FIFO/vip/pyuvm`: run the Python UVM bench.
- `make -C FIFO/vip/cpp run`: build and run the C++17 bench with Verilator.

Replace `FIFO` with the affected block where supported. Run `make clean` in the bench directory after changing DUT parameters.

## Coding Style & Naming Conventions

Follow neighboring files; use four-space indentation in SystemVerilog and Python, and tabs for Makefile recipes. Use snake_case for RTL signals/modules and Python functions, uppercase for parameters such as `DATA_WIDTH`, and existing VIP prefixes such as `fifo_vip_`. Keep RTL synthesizable and update source lists when adding dependencies. No repository-wide formatter or linter is configured.

## Testing Guidelines

Extend `tb.sv`, cocotb `tb.py`, or VIP tests named `<prefix>_vip_<scenario>_test.py`/`.sv`. Check reset, boundary conditions, simultaneous operations, and relevant parameter combinations against assertions or scoreboards. No numeric coverage threshold is defined. Record commands, parameters, seeds, and results; inspect simulation logs for failures.

## Commit & Pull Request Guidelines

History uses short descriptive subjects such as `add pyUVM VIP`; no enforced commit prefix scheme is evident. Use an imperative subject identifying the affected block. PRs should explain behavior changes, link relevant issues, list verification results, and update interface documentation. Include waveforms when they clarify timing changes. Keep generated simulation outputs and build directories out of commits.
