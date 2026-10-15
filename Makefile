.DEFAULT_GOAL := help
.PHONY: help check regress synth netlist checkers ci test-tools
PYTHON ?= python3
MODULES ?=
JOBS ?= 1
SEED ?= 123
ARTIFACT_DIR ?= sim_build/verification
VERIFY_ARGS = --jobs $(JOBS) --seed $(SEED) --output $(ARTIFACT_DIR) $(foreach module,$(MODULES),--module $(module))

help:
	@echo "make check     - default real-RTL SV/cocotb checks"
	@echo "make regress   - complete verified parameter/seed regressions"
	@echo "make synth     - synthesis and structural/no-latch checks"
	@echo "make netlist   - SLL/DLL mapped-netlist functional simulations"
	@echo "make checkers  - testbench fault/timeout rejection checks"
	@echo "make ci        - regressions, checker checks, synthesis and netlists"
	@echo "make test-tools - verification runner self-tests"
	@echo "MODULES='systolic list circular singly doubly' selects modules"

check regress synth netlist checkers ci:
	$(PYTHON) Utils/ci/verify.py --suite $@ $(VERIFY_ARGS)

test-tools:
	$(PYTHON) -m unittest discover -s Utils/ci/tests -v
