SEED ?= 1
DATA_WIDTH ?= 8
LENGTH ?= 8
SUM_METHOD ?= 0
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD
RTL_SOURCES ?= $(abspath ../../src/list.sv) $(abspath ../../src/adder.sv) $(abspath ../../src/sorter.sv)
TOPLEVEL = list

include ../../../Utils/tb/cocotb/Makefile
