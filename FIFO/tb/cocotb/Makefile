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
TOPLEVEL = fifo

include ../../../Utils/tb/cocotb/Makefile
