SEED ?= 123
DATA_WIDTH ?= 8
DEPTH ?= 12
TB_TIMEOUT_CYCLES ?= 20000
PARAMETERS = DATA_WIDTH DEPTH
RTL_SOURCES ?= $(abspath ../../src/lifo.sv)
TOPLEVEL = lifo

include ../../../Utils/tb/cocotb/Makefile
