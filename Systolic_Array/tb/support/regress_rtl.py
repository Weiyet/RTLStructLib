"""Run both real-RTL benches across dimensions, widths, skew modes and seeds."""

from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET


TB_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = TB_DIR.parent / "src"
SOURCES = " ".join(str(SRC_DIR / name) for name in
                   ("pe.sv", "systolic_array.sv", "systolic_array_top.sv"))
CONFIGS = [
    ("default", {}),
    ("rectangular_unsigned", {"ARRAY_ROWS": 2, "ARRAY_COLS": 3, "K_DIM": 4,
                              "DATA_WIDTH": 5, "WEIGHT_WIDTH": 7, "ACC_WIDTH": 16, "SIGNED_MATH": 0}),
    ("single_lane_overflow", {"ARRAY_ROWS": 1, "ARRAY_COLS": 1, "K_DIM": 3,
                              "DATA_WIDTH": 3, "WEIGHT_WIDTH": 4, "ACC_WIDTH": 7}),
    ("short_k", {"ARRAY_ROWS": 4, "ARRAY_COLS": 2, "K_DIM": 1}),
    ("partial_tiles", {"ARRAY_ROWS": 3, "ARRAY_COLS": 5, "K_DIM": 7}),
    ("external_skew", {"ARRAY_ROWS": 3, "ARRAY_COLS": 2, "K_DIM": 5, "INPUT_SKEW": 0}),
    ("external_skew_unsigned", {"ARRAY_ROWS": 2, "ARRAY_COLS": 4, "K_DIM": 3,
                                 "DATA_WIDTH": 4, "WEIGHT_WIDTH": 6, "ACC_WIDTH": 10,
                                 "SIGNED_MATH": 0, "INPUT_SKEW": 0}),
    ("one_bit", {"ARRAY_ROWS": 2, "ARRAY_COLS": 3, "K_DIM": 5,
                  "DATA_WIDTH": 1, "WEIGHT_WIDTH": 1, "ACC_WIDTH": 2}),
    ("wide_accumulator", {"ARRAY_ROWS": 2, "ARRAY_COLS": 1, "K_DIM": 3,
                           "DATA_WIDTH": 16, "WEIGHT_WIDTH": 12, "ACC_WIDTH": 64, "SIGNED_MATH": 0}),
    ("single_element", {"ARRAY_ROWS": 1, "ARRAY_COLS": 1, "K_DIM": 1,
                         "DATA_WIDTH": 3, "WEIGHT_WIDTH": 4, "ACC_WIDTH": 7, "INPUT_SKEW": 0}),
]


def run(bench, build_dir, config, seed):
    command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
               f"SIM_BUILD={build_dir}", f"SEED={seed}", "WAVES=0"]
    command.extend(f"{name}={value}" for name, value in config.items())
    if bench == "sv":
        command.extend([f"SIM_OPTS={SOURCES}", "TEST=all"])
    else:
        command.extend([f"RTL_SOURCES={SOURCES}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                        "TESTCASE=", "COCOTB_TEST_FILTER="])
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=60)
    if result.returncode != 0:
        print(result.stdout)
        raise AssertionError(f"{bench} RTL regression failed: seed={seed}, config={config}")
    if bench == "sv":
        assert "ALL TESTS PASSED" in result.stdout
    else:
        cases = ET.parse(build_dir / "results.xml").getroot().findall(".//testcase")
        assert len(cases) == 12 and not any(case.find("failure") is not None or
                                          case.find("error") is not None for case in cases)


def main():
    checks = 0
    with tempfile.TemporaryDirectory(prefix="systolic-rtl-") as scratch:
        root = Path(scratch)
        for bench in ("sv", "cocotb"):
            for name, config in CONFIGS:
                run(bench, root / f"{bench}-{name}", config, 123)
                checks += 1
                print(f"PASS real RTL {bench}: {name}, seed=123", flush=True)
        for seed in range(20):
            run("cocotb", root / f"seed-{seed}", {}, seed)
            checks += 1
            print(f"PASS real RTL cocotb: default, seed={seed}", flush=True)
    print(f"All {checks} real-RTL regression runs passed.")


if __name__ == "__main__":
    main()
