"""Real-RTL parameter/clock regressions for storage blocks."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Utils/tb"))
from check_results import validate_results

BLOCKS = {"fifo": ("FIFO", "fifo", 5), "table": ("Table", "table_top", 5),
          "hash": ("Hash_Table", "hash_table", 6)}
CONFIGS = {
    "hash": [{}, dict(TOTAL_INDEX=1, CHAINING_SIZE=1, KEY_WIDTH=1, VALUE_WIDTH=1),
             dict(TOTAL_INDEX=2, CHAINING_SIZE=2, KEY_WIDTH=3, VALUE_WIDTH=8),
             dict(TOTAL_INDEX=3, CHAINING_SIZE=3, KEY_WIDTH=17, VALUE_WIDTH=9),
             dict(TOTAL_INDEX=5, CHAINING_SIZE=2, KEY_WIDTH=40, VALUE_WIDTH=40),
             dict(TOTAL_INDEX=1, CHAINING_SIZE=5, KEY_WIDTH=8, VALUE_WIDTH=17)],
    "table": [{}, dict(TABLE_SIZE=1, DATA_WIDTH=1, INPUT_RATE=1, OUTPUT_RATE=1),
              dict(TABLE_SIZE=3, DATA_WIDTH=17, INPUT_RATE=3, OUTPUT_RATE=2),
              dict(TABLE_SIZE=8, DATA_WIDTH=40, INPUT_RATE=2, OUTPUT_RATE=3),
              dict(TABLE_SIZE=5, DATA_WIDTH=8, INPUT_RATE=1, OUTPUT_RATE=4),
              dict(TABLE_SIZE=17, DATA_WIDTH=1, INPUT_RATE=4, OUTPUT_RATE=1)],
    "fifo": [dict(ASYNC=mode, RD_BUFFER=buffered, DEPTH=depth, DATA_WIDTH=width)
             for mode, dimensions in ((0, [(1, 1), (3, 17), (12, 40)]),
                                      (1, [(2, 1), (4, 17), (16, 8)]))
             for depth, width in dimensions for buffered in (0, 1)]
}


def invoke(command, log):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=180)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        output, _ = process.communicate()
        log.write_text(output)
        raise AssertionError(f"Host timeout: {command}") from None
    log.write_text(output)
    return process.returncode, output


def run(module, bench, config, seed, waves, build, negative=None):
    directory, top, tests = BLOCKS[module]
    build.mkdir(parents=True)
    command = ["make", "-C", str(ROOT / directory / "tb" / bench),
               "sim" if bench == "sv" else "check", f"SIM_BUILD={build}",
               f"SEED={seed}", f"WAVES={waves}"]
    command.extend(f"{key}={value}" for key, value in config.items())
    source = ROOT / directory / "src" / ("table.sv" if module == "table" else f"{top}.sv")
    if bench == "sv":
        command.append(f"SIM_OPTS={source}")
    else:
        command.extend([f"RTL_SOURCES={source}", f"COCOTB_RESULTS_FILE={build}/results.xml",
                        "TESTCASE=test_empty_and_invalid" if negative else "TESTCASE=",
                        "COCOTB_TEST_FILTER="])
    code, output = invoke(command, build / "command.log")
    if negative:
        assert code != 0 and negative in output.lower(), output
    else:
        assert code == 0, output
        if bench == "sv":
            assert re.search(r"ALL TESTS PASSED: [1-9][0-9]* transactions", output), output
        else:
            assert validate_results(build / "results.xml", tests) == tests
        if waves:
            assert (build / ("sim.vcd" if bench == "sv" else f"{top}.fst")).stat().st_size > 0
    print(f"PASS {module}/{bench}: {config}, seed={seed}, waves={waves}"
          + (f", rejected {negative}" if negative else ""), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", choices=BLOCKS, required=True)
    options = parser.parse_args()
    module = options.module
    cases = [(bench, config, 123, 0) for config in CONFIGS[module] for bench in ("sv", "cocotb")]
    if module == "fifo":
        cases.extend((bench, dict(DEPTH=4, ASYNC=1, RD_BUFFER=buffered,
                                  WR_HALF=write, RD_HALF=read), 123, 0)
                     for write, read in ((5, 2), (2, 5), (3, 3))
                     for buffered in (0, 1) for bench in ("sv", "cocotb"))
    cases.extend((bench, {}, seed, 0) for seed in (0, 19) for bench in ("sv", "cocotb"))
    cases.extend((bench, {}, 123, 1) for bench in ("sv", "cocotb"))
    negatives = 0
    with tempfile.TemporaryDirectory(prefix=f"{module}-rtl-") as scratch:
        root = Path(scratch)
        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(run, module, bench, config, seed, waves, root / f"run-{i}")
                       for i, (bench, config, seed, waves) in enumerate(cases)]
            for future in futures:
                future.result()
        for bench in ("sv", "cocotb"):
            run(module, bench, {"TB_TIMEOUT_CYCLES": 1}, 123, 0,
                root / f"timeout-{bench}", "timed out")
            negatives += 1
        if module == "fifo":
            for index, config in enumerate(({"DEPTH": 3}, {"DEPTH": 1},
                                            {"ASYNC": 2}, {"RD_BUFFER": 2})):
                run(module, "sv", config, 123, 0, root / f"invalid-{index}",
                    "power of two" if "DEPTH" in config else "must be")
                negatives += 1
        if module == "hash":
            for parameter in ("HASH_ALGORITHM", "COLLISION_METHOD"):
                fixture = root / f"invalid-{parameter}.sv"
                fixture.write_text(f'module tb; hash_table #(.{parameter}("BAD")) dut(); endmodule\n')
                binary = root / f"invalid-{parameter}.sim"
                code, output = invoke(["iverilog", "-g2012", "-s", "tb", "-o", str(binary),
                                       str(fixture), str(ROOT / "Hash_Table/src/hash_table.sv")],
                                      root / f"invalid-{parameter}-compile.log")
                assert code == 0, output
                code, output = invoke(["vvp", str(binary)], root / f"invalid-{parameter}.log")
                assert code != 0 and "Unsupported Hash Table" in output, output
                print(f"PASS hash: rejected unsupported {parameter}", flush=True)
                negatives += 1
    print(f"All {len(cases)} real-RTL runs and {negatives} failure-status checks passed.")


if __name__ == "__main__":
    main()
