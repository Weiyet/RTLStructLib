.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 123
KEY_WIDTH ?= 32
VALUE_WIDTH ?= 32
TOTAL_INDEX ?= 8
CHAINING_SIZE ?= 4
TB_TIMEOUT_CYCLES ?= 100
PARAMETERS = KEY_WIDTH VALUE_WIDTH TOTAL_INDEX CHAINING_SIZE
RTL_SOURCES ?= $(abspath ../../src/hash_table.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = hash_table
MODULE = tb
COCOTB_TEST_MODULES = $(MODULE)
COMPILE_ARGS += $(foreach param,$(PARAMETERS),-P$(TOPLEVEL).$(param)=$($(param))) $(TB_COMPILE_ARGS)
export TB_SEED = $(SEED)
export TB_TIMEOUT_CYCLES
export RANDOM_SEED = $(SEED)
export COCOTB_RANDOM_SEED = $(SEED)
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps
SIM_BUILD ?= sim_build
include $(shell cocotb-config --makefiles)/Makefile.sim
.PHONY: check
check: sim
	python3 ../../../Utils/tb/check_results.py $(COCOTB_RESULTS_FILE)