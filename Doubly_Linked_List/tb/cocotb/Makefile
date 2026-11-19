SEED ?= 1
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE
RTL_SOURCES ?= $(abspath ../../src/doubly_linked_list.sv)
TOPLEVEL = doubly_linked_list
export PYTHONPATH := $(abspath ../../../Singly_Linked_List/tb/shared):$(PYTHONPATH)

include ../../../Utils/tb/cocotb/Makefile
