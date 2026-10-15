"""Compatibility entry point for the shared repository result checker."""
from pathlib import Path
import runpy

if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).resolve().parents[3] / "Utils/tb/check_results.py"),
                   run_name="__main__")
