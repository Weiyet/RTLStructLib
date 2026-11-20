"""Require completed, nonempty UVM checking and reject reported UVM errors."""
import re
import sys
from pathlib import Path


def validate(text):
    for line in text.splitlines():
        if re.search(r"\bUVM_(?:ERROR|FATAL)\b", line):
            if not re.search(r"\bUVM_(?:ERROR|FATAL)\s*:\s*0\s*$", line):
                raise ValueError(f"UVM failure: {line}")
    match = re.search(r"VIP PASSED: ([1-9][0-9]*) transactions", text)
    if not match:
        raise ValueError("Missing nonempty VIP completion marker")
    return int(match[1])


if __name__ == "__main__":
    print(f"SV UVM check passed: {validate(Path(sys.argv[1]).read_text())} transactions")
