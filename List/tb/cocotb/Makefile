.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 1
DATA_WIDTH ?= 8
LENGTH ?= 8
SUM_METHOD ?= 0
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD

RTL_SOURCES ?= $(abspath ../../src/list.sv) $(abspath ../../src/adder.sv) $(abspath ../../src/sorter.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = list
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


