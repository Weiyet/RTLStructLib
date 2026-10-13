.DEFAULT_GOAL := check
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 0
SEED ?= 1
TB_TIMEOUT_CYCLES ?= 1000

ARRAY_ROWS ?= 4
ARRAY_COLS ?= 4
K_DIM ?= 4
DATA_WIDTH ?= 8
WEIGHT_WIDTH ?= 8
ACC_WIDTH ?= 32
SIGNED_MATH ?= 1
INPUT_SKEW ?= 1
PARAMETERS = ARRAY_ROWS ARRAY_COLS K_DIM DATA_WIDTH WEIGHT_WIDTH ACC_WIDTH SIGNED_MATH INPUT_SKEW

RTL_SOURCES ?= $(abspath ../../src/pe.sv) $(abspath ../../src/systolic_array.sv) $(abspath ../../src/systolic_array_top.sv)
VERILOG_SOURCES = $(RTL_SOURCES)
TOPLEVEL = systolic_array_top
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
	python3 ../support/check_results.py $(COCOTB_RESULTS_FILE)
