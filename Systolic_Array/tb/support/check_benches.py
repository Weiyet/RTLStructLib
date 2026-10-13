"""Prove both benches accept a contract model and reject injected failures."""

from pathlib import Path
import subprocess
import tempfile


TB_DIR = Path(__file__).resolve().parent.parent
MODEL = TB_DIR / "support" / "contract_model.sv"
CONFIGS = [
    {},
    {"ARRAY_ROWS": 2, "ARRAY_COLS": 3, "K_DIM": 4,
     "DATA_WIDTH": 5, "WEIGHT_WIDTH": 7, "ACC_WIDTH": 16, "SIGNED_MATH": 0},
    {"ARRAY_ROWS": 1, "ARRAY_COLS": 1, "K_DIM": 3,
     "DATA_WIDTH": 3, "WEIGHT_WIDTH": 4, "ACC_WIDTH": 7},
    {"ARRAY_ROWS": 3, "ARRAY_COLS": 2, "K_DIM": 5, "INPUT_SKEW": 0},
]
FAULTS = {
    1: ("simple", "result rows"),
    2: ("simple", "result rows"),
    3: ("simple", "Extra result row"),
    4: ("simple", "mismatch"),
    5: ("simple", "Timed out waiting for done"),
    6: ("stalls", "Stalled result changed"),
}


def run_bench(bench, build_dir, config, fault=0, scenario="all", reason=None, waves=False):
    command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
               "SEED=123", f"WAVES={int(waves)}",
               f"SIM_BUILD={build_dir}", "TB_TIMEOUT_CYCLES=200"]
    command.extend(f"{name}={value}" for name, value in config.items())
    if bench == "sv":
        command.extend([f"SIM_OPTS={MODEL}", f"TEST={scenario}",
                        f"COMPILE_ARGS=-DSELFTEST_FAULT={fault}"])
    else:
        command.extend([f"RTL_SOURCES={MODEL}", f"TB_COMPILE_ARGS=-DSELFTEST_FAULT={fault}",
                        f"COCOTB_RESULTS_FILE={build_dir}/results.xml"])
        if scenario != "all":
            name = {"simple": "test_simple_values", "stalls": "test_stalls"}[scenario]
            command.extend([f"TESTCASE={name}", f"COCOTB_TEST_FILTER=^{name}$"])
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=60)
    if reason is None:
        passed = result.returncode == 0 and (
            "ALL TESTS PASSED" in result.stdout if bench == "sv"
            else "FAIL=0" in result.stdout)
    else:
        passed = result.returncode != 0 and reason in result.stdout
    if not passed:
        print(result.stdout)
        raise AssertionError(f"{bench}: config={config}, fault={fault}, exit={result.returncode}")
    if waves:
        wavefile = build_dir / ("sim.vcd" if bench == "sv" else "systolic_array_top.fst")
        assert wavefile.is_file() and wavefile.stat().st_size > 0, f"Missing waveform: {wavefile}"
    label = "accepted model" if reason is None else f"rejected fault {fault} ({reason})"
    print(f"PASS {bench}: {label}; config={config or 'default'}; waves={waves}", flush=True)


def main():
    checks = 0
    with tempfile.TemporaryDirectory(prefix="systolic-checkers-") as scratch:
        root = Path(scratch)
        for bench in ("sv", "cocotb"):
            for index, config in enumerate(CONFIGS):
                run_bench(bench, root / f"{bench}-good-{index}", config)
                checks += 1
            run_bench(bench, root / f"{bench}-waves", {}, scenario="simple", waves=True)
            checks += 1
            for fault, (scenario, reason) in FAULTS.items():
                run_bench(bench, root / f"{bench}-fault-{fault}", {},
                          fault, scenario, reason)
                checks += 1
    print(f"All {checks} checker self-checks passed.")


if __name__ == "__main__":
    main()
