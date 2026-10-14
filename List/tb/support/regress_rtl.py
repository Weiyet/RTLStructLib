"""Regress real List RTL across sum methods, dimensions, widths and seeds."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET


TB_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = TB_DIR.parent / "src"
SOURCES = " ".join(str(SRC_DIR / name) for name in ("list.sv", "adder.sv", "sorter.sv"))
CONFIGS = [(8, 8), (1, 1), (2, 3), (3, 8), (5, 17), (9, 40)]


def run(bench, build_dir, length, width, method, seed, waves=0):
    command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
               f"SIM_BUILD={build_dir}", f"LENGTH={length}", f"DATA_WIDTH={width}",
               f"SUM_METHOD={method}", f"SEED={seed}", f"WAVES={waves}"]
    if bench == "sv":
        command.extend([f"SIM_OPTS={SOURCES}", "TEST=all"])
    else:
        command.extend([f"RTL_SOURCES={SOURCES}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                        "TESTCASE=", "COCOTB_TEST_FILTER="])
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=60)
    assert result.returncode == 0, result.stdout
    if bench == "sv":
        assert "ALL TESTS PASSED" in result.stdout, result.stdout
        if waves:
            assert (build_dir / "sim.vcd").stat().st_size > 0
    else:
        cases = ET.parse(build_dir / "results.xml").getroot().findall(".//testcase")
        assert len(cases) == 7 and all(case.find("failure") is None and
                                     case.find("error") is None and
                                     case.find("skipped") is None for case in cases)
        if waves:
            assert (build_dir / "list.fst").stat().st_size > 0
    return f"{bench}: LENGTH={length}, DATA_WIDTH={width}, SUM_METHOD={method}, SEED={seed}, WAVES={waves}"


def check_failure_status(root):
    # Force a bounded completion failure and require both Makefiles to reject it.
    for bench in ("sv", "cocotb"):
        build_dir = root / f"failure-{bench}"
        command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
                   f"SIM_BUILD={build_dir}", "SUM_METHOD=1", "TB_TIMEOUT_CYCLES=1", "SEED=123", "WAVES=0"]
        if bench == "sv":
            command.extend([f"SIM_OPTS={SOURCES}", "TEST=sum"])
        else:
            command.extend([f"RTL_SOURCES={SOURCES}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                            "TESTCASE=test_repeated_sum_and_maximum", "COCOTB_TEST_FILTER="])
        result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=60)
        assert result.returncode != 0 and "timed out" in result.stdout, result.stdout
        print(f"PASS {bench}: forced timeout rejected", flush=True)


def main():
    checks = 0
    with tempfile.TemporaryDirectory(prefix="list-rtl-") as scratch:
        root = Path(scratch)
        jobs = []
        for bench in ("sv", "cocotb"):
            for length, width in CONFIGS:
                for method in range(3):
                    jobs.append((bench, length, width, method, 123, 0))
            for method in range(3):
                for seed in (0, 1, 19):
                    jobs.append((bench, 8, 8, method, seed, 0))
            jobs.append((bench, 8, 8, 2, 123, 1))
        with ThreadPoolExecutor(max_workers=3) as pool:
            pending = {pool.submit(run, bench, root / f"run-{index}", length, width, method, seed, waves)
                       for index, (bench, length, width, method, seed, waves) in enumerate(jobs)}
            for future in as_completed(pending):
                print(f"PASS real RTL {future.result()}", flush=True)
                checks += 1
        check_failure_status(root)
    print(f"All {checks} real-RTL runs and 2 failure-status checks passed.")


if __name__ == "__main__":
    main()
