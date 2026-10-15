"""Reject missing, malformed, empty, failed, or skipped cocotb results."""

import sys
import xml.etree.ElementTree as ET


def validate_results(path, minimum=1):
    cases = ET.parse(path).getroot().findall(".//testcase")
    failures = [case for case in cases
                if case.find("failure") is not None or case.find("error") is not None]
    skipped = [case for case in cases if case.find("skipped") is not None]
    if len(cases) < minimum or failures or skipped:
        raise ValueError(f"Cocotb results: {len(cases)} tests, {len(failures)} failed, "
                         f"{len(skipped)} skipped; at least {minimum} required")
    return len(cases)


def main(path):
    try:
        count = validate_results(path)
    except (OSError, ET.ParseError, ValueError) as error:
        print(f"Cocotb check failed: {error}")
        return 1
    print(f"Cocotb check passed: {count} tests")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
