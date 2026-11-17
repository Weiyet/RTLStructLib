.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 123
DATA_WIDTH ?= 8
DEPTH ?= 16
TB_TIMEOUT_CYCLES ?= 100000
PRIORITY_WIDTH ?= 8
MIN_FIRST ?= 1
PARAMETERS = PRIORITY_WIDTH MIN_FIRST DATA_WIDTH DEPTH
RTL_SOURCES ?= $(abspath ../../src/priority_queue.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = priority_queue
MODULE = tb_priority
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