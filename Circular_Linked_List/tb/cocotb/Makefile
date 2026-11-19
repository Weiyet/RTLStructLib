SEED ?= 1
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE
RTL_SOURCES ?= $(abspath ../../src/circular_linked_list.sv)
TOPLEVEL = circular_linked_list

include ../../../Utils/tb/cocotb/Makefile
