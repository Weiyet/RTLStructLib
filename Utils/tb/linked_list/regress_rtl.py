"""Bounded hardware regressions for the original singly/doubly list interfaces."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
MODULES = {"singly": ("Singly_Linked_List", "singly_linked_list"),
           "doubly": ("Doubly_Linked_List", "doubly_linked_list")}
CONFIGS = [(8, 8), (1, 1), (2, 3), (3, 8), (5, 17), (9, 40), (17, 1), (33, 8)]
SYNTH_CONFIGS = [(8, 8), (1, 1), (5, 17), (33, 8)]
RUN_TIMEOUT = int(os.getenv("RTL_RUN_TIMEOUT", "180"))


def invoke(command):
    process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=RUN_TIMEOUT)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        output, _ = process.communicate()
        raise AssertionError(f"Host timeout after {RUN_TIMEOUT}s: {command}\n{output}") from None
    return process.returncode, output


def run(name, bench, build_dir, capacity, width, seed, waves=0):
    directory, top = MODULES[name]
    source = ROOT / directory / "src" / f"{top}.sv"
    command = ["make", "-C", str(ROOT / directory / "tb" / bench),
               "sim" if bench == "sv" else "check", f"SIM_BUILD={build_dir}",
               f"MAX_NODE={capacity}", f"DATA_WIDTH={width}", f"SEED={seed}", f"WAVES={waves}"]
    if bench == "sv":
        command.extend([f"SIM_OPTS={source}", "TEST=all"])
    else:
        command.extend([f"RTL_SOURCES={source}", f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                        "TESTCASE=", "COCOTB_TEST_FILTER="])
    code, output = invoke(command)
    description = f"{name}/{bench}: MAX_NODE={capacity}, DATA_WIDTH={width}, SEED={seed}, WAVES={waves}"
    assert code == 0, f"{description}\n{output}"
    if bench == "sv":
        assert "ALL TESTS PASSED" in output, output
        if waves:
            assert (build_dir / "sim.vcd").stat().st_size > 0
    else:
        cases = ET.parse(build_dir / "results.xml").getroot().findall(".//testcase")
        assert len(cases) == 10 and all(case.find("failure") is None and
                                      case.find("error") is None and
                                      case.find("skipped") is None for case in cases)
        if waves:
            assert (build_dir / f"{top}.fst").stat().st_size > 0
    return description


def synthesize(name, build_dir, capacity, width):
    directory, top = MODULES[name]
    # The small configurations also execute the mapped FPGA netlist.
    gate_sim = capacity <= 8
    command = ["make", "-C", str(ROOT / directory / "tb" / "sv"),
               "netlist_sim" if gate_sim else "synth", f"SIM_BUILD={build_dir}",
               f"MAX_NODE={capacity}", f"DATA_WIDTH={width}", "SEED=123", "TEST=all"]
    code, output = invoke(command)
    assert code == 0, output
    assert (build_dir / f"{top}.netlist.v").stat().st_size > 0
    assert "found and reported 0 problems" in (build_dir / "synth.log").read_text()
    if gate_sim:
        assert "ALL TESTS PASSED" in output, output
    return f"{name}: MAX_NODE={capacity}, DATA_WIDTH={width}, mapped-netlist simulation={gate_sim}"


def check_failure_status(root, selected):
    for name in selected:
        directory, _ = MODULES[name]
        for bench in ("sv", "cocotb"):
            build_dir = root / f"failure-{name}-{bench}"
            command = ["make", "-C", str(ROOT / directory / "tb" / bench),
                       "sim" if bench == "sv" else "check", f"SIM_BUILD={build_dir}",
                       "TB_TIMEOUT_CYCLES=1", "SEED=123", "WAVES=0"]
            if bench == "sv":
                command.append("TEST=empty")
            else:
                command.extend([f"COCOTB_RESULTS_FILE={build_dir}/results.xml",
                                "TESTCASE=test_empty_and_invalid", "COCOTB_TEST_FILTER="])
            code, output = invoke(command)
            assert code != 0 and "timed out" in output, output
            print(f"PASS {name}/{bench}: forced timeout rejected", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", choices=MODULES, action="append", dest="selected")
    parser.add_argument("--synth-only", action="store_true")
    options = parser.parse_args()
    selected = options.selected or list(MODULES)
    checks = 0
    with tempfile.TemporaryDirectory(prefix="linked-lists-rtl-") as scratch:
        root = Path(scratch)
        with ThreadPoolExecutor(max_workers=2) as pool:
            if options.synth_only:
                pending = [pool.submit(synthesize, name, root / f"synth-{name}-{capacity}", capacity, width)
                           for name in selected for capacity, width in SYNTH_CONFIGS]
            else:
                jobs = []
                for name in selected:
                    jobs.extend((name, bench, capacity, width, 123, 0)
                                for bench in ("sv", "cocotb") for capacity, width in CONFIGS)
                    jobs.extend((name, "sv", 8, 8, seed, 0) for seed in (0, 1, 19))
                    jobs.extend((name, "cocotb", 8, 8, seed, 0) for seed in range(10))
                    jobs.extend((name, bench, 8, 8, 123, 1) for bench in ("sv", "cocotb"))
                pending = [pool.submit(run, name, bench, root / f"run-{index}", capacity, width, seed, waves)
                           for index, (name, bench, capacity, width, seed, waves) in enumerate(jobs)]
            for future in as_completed(pending):
                print(f"PASS {future.result()}", flush=True)
                checks += 1
        if not options.synth_only:
            check_failure_status(root, selected)
    if options.synth_only:
        print(f"All {checks} synthesis checks passed, including {3*len(selected)} mapped-netlist simulations.")
    else:
        print(f"All {checks} real-RTL runs and {2*len(selected)} failure-status checks passed.")


if __name__ == "__main__":
    main()
