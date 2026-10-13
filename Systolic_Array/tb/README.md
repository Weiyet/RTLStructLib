# Systolic Array Verification

## Transaction Contract

Both benches check `C = A * B`, with `M = ARRAY_ROWS`, `N = ARRAY_COLS`,
and `K = K_DIM`. Lane zero occupies the least significant bits. Inputs
are interpreted according to `SIGNED_MATH`; results wrap to `ACC_WIDTH` bits.
The suite covers both `INPUT_SKEW` modes and requires
`ACC_WIDTH >= DATA_WIDTH + WEIGHT_WIDTH`. Numerical-limit tests also check
maximum products and accumulator wrap.

To exercise the existing top, load each packed row of B `ARRAY_ROWS` times
(K*M accepted weight transfers), then send K packed columns of A when
`INPUT_SKEW=1`. With `INPUT_SKEW=0`, send K+M-1 beats; lane r on accepted
beat t contains A[r,t-r] when that index exists, otherwise zero padding.

Transfer only on `valid && ready`. Exactly M result rows must be accepted
before `done`, including a possible final transfer on the `done` edge.
Output data and valid must remain stable while stalled. `done` is a
one-cycle pulse, with `busy` low, and no further output may follow it.

## Running Tests

Run from the repository root in Linux/WSL with Make, Bash, Icarus Verilog,
Python 3, and cocotb available on PATH:

```bash
make -C Systolic_Array/tb/sv sim SEED=123 TEST=simple
make -C Systolic_Array/tb/cocotb SEED=123
python3 Systolic_Array/tb/support/check_benches.py
python3 Systolic_Array/tb/support/regress_rtl.py
make -C Systolic_Array/tb/sv synth
```

The SV `TEST` selector also accepts `all` (default), `identity`, `random`,
`zero`, `signed`, `limits`, `input_gaps`, `output_backpressure`, `stalls`,
`back_to_back`, `reset_weights`, and `reset_compute`. Cocotb exposes the
corresponding individual `test_*` functions.

Both Makefiles accept dimension/width overrides, `SIGNED_MATH`,
`TB_TIMEOUT_CYCLES` (default 1000), and `WAVES=1`. For example:

```bash
make -C Systolic_Array/tb/cocotb clean
make -C Systolic_Array/tb/cocotb ARRAY_ROWS=2 ARRAY_COLS=3 K_DIM=4 SIGNED_MATH=0
```

Clean before changing parameters or source overrides. Build products and
optional waveforms (SV VCD / cocotb Icarus FST) reside in `sim_build/`.
The SV pipeline preserves simulator
failure status; the default cocotb `check` target also rejects failed or
empty XML results, including on older cocotb releases. Use `make` or
`make check` for cocotb rather than its upstream `sim` target alone.

## Checker Validation and RTL Status

`support/contract_model.sv` is a behavioral fixture, not synthesizable RTL
or a replacement DUT. The self-check runner verifies both benches against
default, rectangular unsigned, narrow signed, and externally skewed configurations. It also
requires nonzero exits for no results, missing/extra rows, wrong data,
completion timeout, and unstable stalled output. Waveform generation is
also checked for both benches: 22 checks in total.

Validated on 2026-10-13 with Icarus Verilog 11.0, cocotb 1.8.1 and Yosys 0.9:

- Repaired default RTL: all 12 cocotb scenarios pass with `SEED=123`;
  SV passes all 19 transactions. The fixed matrix first row is
  `[90, 100, 110, 120]` in both benches.
- `regress_rtl.py`: all 40 real-RTL runs pass. Ten configurations run in
  each bench, followed by default cocotb seeds 0 through 19. This covers
  K below/above the physical row count, partial tiles, both skew modes,
  1-bit operands, 64-bit accumulators, and signed/unsigned arithmetic.
- All 22 checker self-checks pass, including six rejected faults per bench.
- `make synth`: the top-level Xilinx synthesis, `check -assert`, and
  no-latch assertion pass. Matrix memories map to registers in this flow.
