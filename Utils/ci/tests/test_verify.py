"""Exercise failure propagation using real subprocesses and result files."""

import contextlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify


@unittest.skipUnless(os.name == "posix", "Runner requires Linux/WSL process groups")
class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)

    def job(self, code, validator="sv", outputs=None, **kwargs):
        return verify.Job("singly", "rtl", "fixture",
                          [sys.executable, "-c", code], self.directory / "run",
                          validator, outputs or [], **kwargs)

    def run_quietly(self, job):
        with contextlib.redirect_stdout(io.StringIO()):
            return verify.run_job(job)

    def test_exit_zero_requires_completion(self):
        self.assertFalse(self.run_quietly(self.job("print('simulation started')"))["passed"])
        self.assertFalse(self.run_quietly(self.job("print('ALL TESTS PASSED 0 transactions')"))["passed"])
        result = self.run_quietly(self.job("print('ALL TESTS PASSED (3 transactions)')"))
        self.assertTrue(result["passed"])
        self.assertEqual(result["metrics"], {"transactions": 3, "real_rtl_runs": 1})

    def test_nonzero_exit_overrides_pass_marker(self):
        result = self.run_quietly(self.job("print('ALL TESTS PASSED 3 transactions'); exit(7)"))
        self.assertFalse(result["passed"])
        self.assertEqual(result["returncode"], 7)

    def test_xml_rejects_invalid_or_incomplete_reports(self):
        reports = ["<testsuites/>", "<broken", "<testsuite><testcase><failure/></testcase></testsuite>",
                   "<testsuite><testcase><error/></testcase></testsuite>",
                   "<testsuite><testcase><skipped/></testcase></testsuite>",
                   "<testsuite><testcase/></testsuite>"]
        report = self.directory / "results.xml"
        for xml in reports:
            with self.subTest(xml=xml):
                code = f"from pathlib import Path; Path({str(report)!r}).write_text({xml!r})"
                self.assertFalse(self.run_quietly(self.job(code, "xml", [report], minimum=2))["passed"])
        xml = "<testsuites><testsuite><testcase/><testcase/></testsuite></testsuites>"
        code = f"from pathlib import Path; Path({str(report)!r}).write_text({xml!r})"
        result = self.run_quietly(self.job(code, "xml", [report], minimum=2))
        self.assertTrue(result["passed"])
        self.assertEqual(result["metrics"]["cocotb_tests"], 2)

    def test_stale_success_report_is_removed(self):
        report = self.directory / "results.xml"
        report.write_text("<testsuite><testcase/></testsuite>")
        result = self.run_quietly(self.job("pass", "xml", [report]))
        self.assertFalse(result["passed"])
        self.assertFalse(report.exists())

    def test_injected_failure_requires_expected_reason(self):
        self.assertFalse(self.run_quietly(self.job("exit(1)", "expected-timeout"))["passed"])
        self.assertFalse(self.run_quietly(self.job("print('timed out')", "expected-timeout"))["passed"])
        result = self.run_quietly(self.job("print('Operation timed out'); exit(1)", "expected-timeout"))
        self.assertTrue(result["passed"])
        self.assertEqual(result["metrics"], {"checker_checks": 1})

    def test_timeout_kills_descendants_and_retains_log(self):
        marker = self.directory / "orphan"
        child = f"import time; from pathlib import Path; time.sleep(0.6); Path({str(marker)!r}).touch()"
        code = (f"import subprocess, sys, time; subprocess.Popen([sys.executable, '-c', {child!r}]); "
                "print('started', flush=True); time.sleep(10)")
        result = self.run_quietly(self.job(code, timeout=0.25))
        self.assertFalse(result["passed"])
        self.assertIn("Host timeout", result["error"])
        self.assertIn("started", Path(result["log"]).read_text())
        time.sleep(0.7)
        self.assertFalse(marker.exists())

    def test_failure_emits_report_and_later_checks_still_run(self):
        failed = self.job("exit(4)")
        passed = self.job("print('ALL TESTS PASSED 2 transactions')")
        passed.name = "later"
        passed.directory = self.directory / "later"
        output = self.directory / "reports"
        with patch.object(verify, "plan_jobs", return_value=[failed, passed]), \
                patch.object(verify, "tool_versions", return_value={}), \
                patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(self.directory / "step.md")}), \
                contextlib.redirect_stdout(io.StringIO()):
            status = verify.main(["--output", str(output), "--module", "singly"])
        report = json.loads((output / "summary.json").read_text())
        self.assertEqual(status, 1)
        self.assertFalse(report["passed"])
        self.assertEqual([job["passed"] for job in report["jobs"]], [False, True])
        self.assertIn("1/2 jobs passed", (output / "summary.md").read_text())
        self.assertTrue((self.directory / "step.md").is_file())


if __name__ == "__main__":
    unittest.main()
