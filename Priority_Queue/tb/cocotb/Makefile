SEED ?= 123
DATA_WIDTH ?= 8
DEPTH ?= 16
TB_TIMEOUT_CYCLES ?= 100000
PRIORITY_WIDTH ?= 8
MIN_FIRST ?= 1
PARAMETERS = PRIORITY_WIDTH MIN_FIRST DATA_WIDTH DEPTH
RTL_SOURCES ?= $(abspath ../../src/priority_queue.sv)
TOPLEVEL = priority_queue

include ../../../Utils/tb/cocotb/Makefile
