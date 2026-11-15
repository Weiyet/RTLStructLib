.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 123
DATA_WIDTH ?= 8
DEPTH ?= 16
ASYNC ?= 1
RD_BUFFER ?= 1
WR_HALF ?= 3
RD_HALF ?= 5
export WR_HALF RD_HALF
TB_TIMEOUT_CYCLES ?= 100000
PARAMETERS = DATA_WIDTH DEPTH ASYNC RD_BUFFER
RTL_SOURCES ?= $(abspath ../../src/fifo.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = fifo
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