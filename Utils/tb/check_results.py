"""Make failed or empty cocotb result files produce a nonzero exit status."""

import sys
import xml.etree.ElementTree as ET


def main(path):
    cases = ET.parse(path).getroot().findall(".//testcase")
    failures = [case for case in cases
                if case.find("failure") is not None or case.find("error") is not None]
    executed = [case for case in cases if case.find("skipped") is None]
    if not executed or failures:
        print(f"Cocotb check failed: {len(executed)} executed, {len(failures)} failed")
        return 1
    print(f"Cocotb check passed: {len(executed)} tests")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
