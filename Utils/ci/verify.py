"""Run the repository's verified RTL suites with retained, separate hardware reports."""

import argparse
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from datetime import datetime, timezone
from importlib.metadata import PackageNotFoundError, version
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Utils/tb"))
from check_results import validate_results


MODULES = {
    "systolic": ("Systolic_Array", "systolic_array_top", 12,
                 ("pe.sv", "systolic_array.sv", "systolic_array_top.sv"),
                 "Systolic_Array/tb/support/regress_rtl.py", 40, 0),
    "list": ("List", "list", 7, ("list.sv", "adder.sv", "sorter.sv"),
             "List/tb/support/regress_rtl.py", 56, 2),
    "circular": ("Circular_Linked_List", "circular_linked_list", 8, ("circular_linked_list.sv",),
                 "Circular_Linked_List/tb/support/regress_rtl.py", 31, 2),
    "singly": ("Singly_Linked_List", "singly_linked_list", 10, ("singly_linked_list.sv",),
               "Utils/tb/linked_list/regress_rtl.py", 31, 2),
    "doubly": ("Doubly_Linked_List", "doubly_linked_list", 10, ("doubly_linked_list.sv",),
               "Utils/tb/linked_list/regress_rtl.py", 31, 2),
}
PHASES = ("rtl", "checkers", "synthesis", "netlist")
CAPACITIES = [({}, "default"), ({"MAX_NODE": 1, "DATA_WIDTH": 1}, "single"),
              ({"MAX_NODE": 5, "DATA_WIDTH": 17}, "odd"),
              ({"MAX_NODE": 33, "DATA_WIDTH": 8}, "wide-pool")]


@dataclass
class Job:
    module: str
    phase: str
    name: str
    command: list[str]
    directory: Path
    validator: str
    outputs: list[Path] = field(default_factory=list)
    minimum: int = 1
    negatives: int = 0
    timeout: float = 1200


def hardware_configs(module):
    if module == "systolic":
        return [({}, "default")]
    if module == "list":
        return [({"SUM_METHOD": method}, f"sum-{method}") for method in range(3)] + [
            ({"SUM_METHOD": 2, "LENGTH": 1, "DATA_WIDTH": 1}, "tree-single"),
            ({"SUM_METHOD": 2, "LENGTH": 5, "DATA_WIDTH": 17}, "tree-odd")]
    return CAPACITIES


def make_command(module, bench, target, build, config, seed):
    directory, top, _, sources, *_ = MODULES[module]
    source_list = " ".join(str(ROOT / directory / "src" / source) for source in sources)
    command = ["make", "-C", str(ROOT / directory / "tb" / bench), target,
               f"SIM_BUILD={build}", f"SEED={seed}", "WAVES=0"]
    command.extend(f"{key}={value}" for key, value in config.items())
    if bench == "sv":
        command.extend([f"SIM_OPTS={source_list}", "TEST=all"])
    else:
        command.extend([f"RTL_SOURCES={source_list}", "TESTCASE=", "COCOTB_TEST_FILTER=",
                        f"COCOTB_RESULTS_FILE={build}/results.xml"])
    return command


def plan_jobs(suite, selected, output, seed):
    jobs = []
    for module in selected:
        directory, top, tests, _, script, runs, negatives = MODULES[module]
        if suite == "check":
            configs = [({"SUM_METHOD": method}, f"sum-{method}") for method in range(3)] if module == "list" else [({}, "default")]
            for config, label in configs:
                for bench in ("sv", "cocotb"):
                    location = output / module / "rtl" / f"{bench}-{label}"
                    build = location / "build"
                    xml = [build / "results.xml"] if bench == "cocotb" else []
                    jobs.append(Job(module, "rtl", f"{bench}-{label}",
                                    make_command(module, bench, "sim" if bench == "sv" else "check",
                                                 build, config, seed), location,
                                    "xml" if xml else "sv", xml, tests if xml else 1, timeout=300))
        if suite in ("regress", "ci"):
            command = [sys.executable, "-u", str(ROOT / script)]
            if module in ("singly", "doubly"):
                command.extend(["--module", module])
            jobs.append(Job(module, "rtl", "full-regression", command,
                            output / module / "rtl/full-regression", "regression",
                            minimum=runs, negatives=negatives))
        if suite in ("checkers", "ci") and module == "systolic":
            jobs.append(Job(module, "checkers", "fault-models",
                            [sys.executable, "-u", str(ROOT / "Systolic_Array/tb/support/check_benches.py")],
                            output / module / "checkers/fault-models", "checker-suite", minimum=22))
        if suite == "checkers" and module != "systolic":
            for bench in ("sv", "cocotb"):
                location = output / module / "checkers" / f"timeout-{bench}"
                config = {"TB_TIMEOUT_CYCLES": 1}
                if module == "list":
                    config["SUM_METHOD"] = 1
                command = make_command(module, bench, "sim" if bench == "sv" else "check",
                                       location / "build", config, seed)
                command.append(f"TEST={'sum' if module == 'list' else 'empty'}")
                if bench == "cocotb":
                    command.append(f"TESTCASE={'test_repeated_sum_and_maximum' if module == 'list' else 'test_empty_and_invalid'}")
                jobs.append(Job(module, "checkers", f"timeout-{bench}", command,
                                location, "expected-timeout", timeout=300))
        if suite in ("synth", "netlist", "ci"):
            for config, label in hardware_configs(module):
                if suite == "netlist" and label == "wide-pool":
                    continue
                build = output / module / "hardware" / label
                netlist = build / f"{top}.netlist.v"
                synth_log = build / "synth.log"
                command = make_command(module, "sv", "synth", build, config, seed)
                if module == "systolic":
                    command.extend([f"NETLIST={netlist}", f"SYNTH_LOG={synth_log}"])
                jobs.append(Job(module, "synthesis", label, command,
                                output / module / "synthesis" / label, "synthesis",
                                [synth_log, netlist], timeout=300))
                if module in ("singly", "doubly") and suite in ("netlist", "ci") and label != "wide-pool":
                    command = make_command(module, "sv", "netlist_sim", build, config, seed)
                    command.append("SKIP_SYNTH=1")
                    jobs.append(Job(module, "netlist", label, command,
                                    output / module / "netlist" / label, "sv", timeout=300))
    return jobs


def validate_job(job, code, text):
    metrics = {}
    if job.validator == "expected-timeout":
        if code == 0 or "timed out" not in text.lower():
            raise ValueError("Expected an operation timeout and a nonzero Make exit")
        return {"checker_checks": 1}
    if code != 0:
        raise ValueError(f"Command returned {code}")
    if job.validator == "xml":
        metrics["cocotb_tests"] = validate_results(job.outputs[0], job.minimum)
        metrics["real_rtl_runs"] = 1
    elif job.validator == "sv":
        match = re.search(r"ALL TESTS PASSED[^\n]*?(\d+) transactions", text)
        if not match or int(match[1]) == 0:
            raise ValueError("Missing nonempty SV completion marker")
        metrics["transactions"] = int(match[1])
        metrics["netlist_runs" if job.phase == "netlist" else "real_rtl_runs"] = 1
    elif job.validator == "regression":
        match = re.search(r"All (\d+) real-RTL(?: regression)? runs(?: and (\d+) failure-status checks)? passed\.", text)
        if not match or int(match[1]) < job.minimum or int(match[2] or 0) < job.negatives:
            raise ValueError("Missing complete real-RTL regression summary")
        metrics = {"real_rtl_runs": int(match[1]), "checker_checks": int(match[2] or 0)}
    elif job.validator == "checker-suite":
        match = re.search(r"All (\d+) checker self-checks passed\.", text)
        if not match or int(match[1]) < job.minimum:
            raise ValueError("Missing complete checker self-test summary")
        metrics = {"checker_checks": int(match[1])}
    elif job.validator == "synthesis":
        if any(not item.is_file() or item.stat().st_size == 0 for item in job.outputs):
            raise ValueError("Missing synthesis log or mapped netlist")
        if "found and reported 0 problems" not in job.outputs[0].read_text():
            raise ValueError("Missing successful synthesis structural check")
        metrics = {"synthesis_runs": 1}
    else:
        raise ValueError(f"Unknown validator: {job.validator}")
    return metrics


def run_job(job):
    log = job.directory / "command.log"
    start = time.monotonic()
    result = {"module": job.module, "phase": job.phase, "name": job.name,
              "command": job.command, "log": str(log), "passed": False, "metrics": {}}
    print(f"START {job.module}/{job.phase}/{job.name}", flush=True)
    environment = os.environ.copy()
    for name in ("MAKEFLAGS", "MFLAGS", "MAKEOVERRIDES", "PYTHONOPTIMIZE"):
        environment.pop(name, None)
    environment["PYTHONUNBUFFERED"] = "1"
    try:
        job.directory.mkdir(parents=True, exist_ok=True)
        # Do not accept an XML report or netlist left by an earlier invocation.
        for artifact in job.outputs:
            artifact.parent.mkdir(parents=True, exist_ok=True)
            artifact.unlink(missing_ok=True)
        with log.open("w") as stream:
            process = subprocess.Popen(job.command, cwd=ROOT, env=environment,
                                       stdout=stream, stderr=subprocess.STDOUT,
                                       start_new_session=True)
            try:
                code = process.wait(timeout=job.timeout)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
                raise ValueError(f"Host timeout after {job.timeout}s") from None
        result["returncode"] = code
        result["metrics"] = validate_job(job, code, log.read_text(errors="replace"))
        result["passed"] = True
    except (OSError, ET.ParseError, ValueError) as error:
        result["error"] = str(error)
    finally:
        result["seconds"] = round(time.monotonic() - start, 3)
    status = "PASS" if result["passed"] else "FAIL"
    print(f"{status} {job.module}/{job.phase}/{job.name} ({result['seconds']}s) - {log}", flush=True)
    if not result["passed"]:
        print(result["error"], flush=True)
    return result


def tool_versions():
    tools = {"python": sys.version.splitlines()[0]}
    for package in ("cocotb", "find-libpython"):
        try:
            tools[package] = version(package)
        except PackageNotFoundError:
            tools[package] = "not installed"
    for name, command in (("iverilog", ["iverilog", "-V"]), ("yosys", ["yosys", "-V"]),
                          ("git_commit", ["git", "rev-parse", "HEAD"])):
        try:
            completed = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, text=True, timeout=10)
            tools[name] = completed.stdout.splitlines()[0] if completed.stdout else "no output"
        except (OSError, subprocess.TimeoutExpired) as error:
            tools[name] = str(error)
    return tools


def write_reports(output, suite, selected, results, tools):
    metrics = {}
    for result in results:
        for key, value in result["metrics"].items():
            metrics[key] = metrics.get(key, 0) + value
    failed = sum(not result["passed"] for result in results)
    report = {"suite": suite, "modules": selected, "utc": datetime.now(timezone.utc).isoformat(),
              "tools": tools, "passed": failed == 0 and bool(results),
              "jobs": results, "metrics": metrics}
    output.mkdir(parents=True, exist_ok=True)
    (output / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    lines = [f"# RTL verification: {suite}", "", f"{len(results)-failed}/{len(results)} jobs passed.", "",
             "| Module | Phase | Check | Result | Seconds |", "|---|---|---|---|---|"]
    lines.extend(f"| {item['module']} | {item['phase']} | {item['name']} | "
                 f"{'PASS' if item['passed'] else 'FAIL'} | {item['seconds']} |" for item in results)
    lines.extend(["", "Counts remain separate: " + ", ".join(f"{key}={value}" for key, value in metrics.items()),
                  "", "Mapped-netlist checks are functional simulations; no placement/routing or STA is included.", ""])
    markdown = "\n".join(lines)
    (output / "summary.md").write_text(markdown)
    if os.getenv("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as stream:
            stream.write(markdown)
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite", choices=("check", "regress", "synth", "netlist", "checkers", "ci"), default="check")
    parser.add_argument("--module", choices=MODULES, action="append", dest="selected")
    parser.add_argument("--output", type=Path, default=ROOT / "sim_build/verification")
    parser.add_argument("--jobs", type=int, default=1)
    parser.add_argument("--seed", type=int, default=123)
    parser.add_argument("--list", action="store_true", help="Show the selected checks without running them")
    options = parser.parse_args(argv)
    selected = list(dict.fromkeys(options.selected or (list(MODULES) if options.suite != "netlist" else ["singly", "doubly"])))
    if options.jobs < 1:
        parser.error("--jobs must be positive")
    if options.suite == "netlist" and any(name not in ("singly", "doubly") for name in selected):
        parser.error("Mapped-netlist plans currently cover singly and doubly only")
    output = options.output.resolve()
    jobs = plan_jobs(options.suite, selected, output, options.seed)
    if options.list:
        for phase in PHASES:
            for job in jobs:
                if job.phase == phase:
                    print(f"{job.module}/{job.phase}/{job.name}: {job.command}")
        return 0
    if os.name != "posix":
        parser.error("Run verification in Linux/WSL")
    output.mkdir(parents=True, exist_ok=True)
    for name in ("summary.json", "summary.md"):
        (output / name).unlink(missing_ok=True)
    tools = tool_versions()
    results = []
    for phase in PHASES:
        phase_jobs = [job for job in jobs if job.phase == phase]
        # Synthesis must finish before the mapped-netlist jobs consume its output.
        with ThreadPoolExecutor(max_workers=options.jobs) as pool:
            results.extend(pool.map(run_job, phase_jobs))
    report = write_reports(output, options.suite, selected, results, tools)
    print(f"Report: {output / 'summary.json'}", flush=True)
    print(json.dumps(report["metrics"], sort_keys=True), flush=True)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
