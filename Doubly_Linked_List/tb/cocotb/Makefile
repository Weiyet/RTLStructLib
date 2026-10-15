.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 1
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE
RTL_SOURCES ?= $(abspath ../../src/doubly_linked_list.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = doubly_linked_list
MODULE = tb
COCOTB_TEST_MODULES = $(MODULE)
COMPILE_ARGS += $(foreach param,$(PARAMETERS),-P$(TOPLEVEL).$(param)=$($(param))) $(TB_COMPILE_ARGS)
export PYTHONPATH := $(abspath ../../../Utils/tb/linked_list):$(PYTHONPATH)
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


