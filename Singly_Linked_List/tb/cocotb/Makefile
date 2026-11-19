SEED ?= 1
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE
RTL_SOURCES ?= $(abspath ../../src/singly_linked_list.sv)
TOPLEVEL = singly_linked_list
export PYTHONPATH := $(abspath ../shared):$(PYTHONPATH)

include ../../../Utils/tb/cocotb/Makefile
