"""Reject missing completion and UVM errors even if the simulator exits zero."""
import re
import sys
from pathlib import Path


def validate(text):
    match = re.search(r"PRIORITY VIP PASSED: ([1-9][0-9]*) responses", text)
    if not match:
        raise ValueError("Missing nonempty Priority VIP completion marker")
    for line in text.splitlines():
        if re.search(r"\bUVM_(?:ERROR|FATAL)\b", line):
            if not re.search(r"\bUVM_(?:ERROR|FATAL)\s*:\s*0\s*$", line):
                raise ValueError(f"UVM failure: {line}")
    return int(match[1])


if __name__ == "__main__":
    print(f"SV UVM check passed: {validate(Path(sys.argv[1]).read_text())} responses")
