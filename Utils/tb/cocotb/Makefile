# Shared cocotb engine, also used by Utils/vip/pyuvm/Makefile.
.DEFAULT_GOAL := check
COCOTB_RULES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 123
SIM_BUILD ?= sim_build
MODULE ?= tb
VERILOG_SOURCES = $(RTL_SOURCES)
COCOTB_TEST_MODULES = $(MODULE)
COMPILE_ARGS += $(foreach param,$(PARAMETERS),-P$(TOPLEVEL).$(param)=$($(param))) $(TB_COMPILE_ARGS)
export TB_SEED = $(SEED)
export TB_TIMEOUT_CYCLES
export RANDOM_SEED = $(SEED)
export COCOTB_RANDOM_SEED = $(SEED)
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Keep help available without loading cocotb's simulator-specific rules.
ifeq ($(MAKECMDGOALS),help)
.PHONY: help
help:
	@echo 'Targets: check (default, simulation + XML validation), sim, clean'
	@echo 'Options: SEED=123 WAVES=1 SIM_BUILD=sim_build TESTCASE=<name>'
	@echo 'Parameters: $(foreach param,$(PARAMETERS),$(param)=$($(param)))'
else
# cocotb owns waveform generation; parsing this file never writes a dump module.
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: check
check: sim
	python3 $(COCOTB_RULES_DIR)../check_results.py $(COCOTB_RESULTS_FILE)
endif
