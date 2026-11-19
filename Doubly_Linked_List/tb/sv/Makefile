DUT = doubly_linked_list
SIM_OPTS ?= ../../src/doubly_linked_list.sv
SEED ?= 1
TEST ?= all
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE TB_TIMEOUT_CYCLES
SYNTH_PARAMETERS = DATA_WIDTH MAX_NODE
NETLIST_DEFINE = LINKED_LIST_NETLIST
TB_INCLUDE_DIRS = ../../../Singly_Linked_List/tb/shared
TB_HEADERS = $(TB_INCLUDE_DIRS)/linked_list_tb.svh

include ../../../Utils/tb/sv/Makefile
