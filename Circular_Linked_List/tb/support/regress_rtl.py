"""Run both circular-list benches against production RTL, including wide pools."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import os
import signal
import subprocess
import tempfile
import xml.etree.ElementTree as ET


TB_DIR = Path(__file__).resolve().parent.parent
SOURCE = TB_DIR.parent / "src" / "circular_linked_list.sv"
CONFIGS = [(8, 8), (1, 1), (2, 3), (3, 8), (5, 17), (9, 40), (17, 1), (33, 8)]
RUN_TIMEOUT = int(os.getenv("RTL_RUN_TIMEOUT", "180"))


def invoke(command):
    # Terminate the whole make/simulator group if a host-time limit expires.
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=RUN_TIMEOUT)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        output, _ = process.communicate()
        raise AssertionError(f"Host timeout after {RUN_TIMEOUT}s: {command}\n{output}") from None
    assert process.returncode == 0, output
    return output


def run(bench, build_dir, capacity, width, seed, waves=0):
    command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
               f"SIM_BUILD={build_dir}", f"MAX_NODE={capacity}", f"DATA_WIDTH={width}",
               f"SEED={seed}", f"WAVES={waves}"]
    if bench == "sv":
        command.extend([f"SIM_OPTS={SOURCE}", "TEST=all"])
    else:
        command.extend([f"RTL_SOURCES={SOURCE}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                        "TESTCASE=", "COCOTB_TEST_FILTER="])
    output = invoke(command)
    if bench == "sv":
        assert "ALL TESTS PASSED" in output, output
        if waves:
            assert (build_dir / "sim.vcd").stat().st_size > 0
    else:
        cases = ET.parse(build_dir / "results.xml").getroot().findall(".//testcase")
        assert len(cases) == 8 and all(case.find("failure") is None and
                                     case.find("error") is None and
                                     case.find("skipped") is None for case in cases)
        if waves:
            assert (build_dir / "circular_linked_list.fst").stat().st_size > 0
    return f"{bench}: MAX_NODE={capacity}, DATA_WIDTH={width}, SEED={seed}, WAVES={waves}"


def check_failure_status(root):
    for bench in ("sv", "cocotb"):
        build_dir = root / f"failure-{bench}"
        command = ["make", "-C", str(TB_DIR / bench), "sim" if bench == "sv" else "check",
                   f"SIM_BUILD={build_dir}", "TB_TIMEOUT_CYCLES=1", "SEED=123", "WAVES=0"]
        if bench == "sv":
            command.extend([f"SIM_OPTS={SOURCE}", "TEST=empty"])
        else:
            command.extend([f"RTL_SOURCES={SOURCE}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                            "TESTCASE=test_empty_and_invalid", "COCOTB_TEST_FILTER="])
        result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=60)
        assert result.returncode != 0 and "timed out" in result.stdout, result.stdout
        print(f"PASS {bench}: forced timeout rejected", flush=True)


def main():
    checks = 0
    with tempfile.TemporaryDirectory(prefix="circular-rtl-") as scratch:
        root = Path(scratch)
        jobs = [(bench, capacity, width, 123, 0) for bench in ("sv", "cocotb")
                for capacity, width in CONFIGS]
        jobs.extend(("sv", 8, 8, seed, 0) for seed in (0, 1, 19))
        jobs.extend(("cocotb", 8, 8, seed, 0) for seed in range(10))
        jobs.extend((bench, 8, 8, 123, 1) for bench in ("sv", "cocotb"))
        with ThreadPoolExecutor(max_workers=2) as pool:
            pending = {pool.submit(run, bench, root / f"run-{index}", capacity, width, seed, waves)
                       for index, (bench, capacity, width, seed, waves) in enumerate(jobs)}
            for future in as_completed(pending):
                print(f"PASS real RTL {future.result()}", flush=True)
                checks += 1
        check_failure_status(root)
    print(f"All {checks} real-RTL runs and 2 failure-status checks passed.")


if __name__ == "__main__":
    main()
