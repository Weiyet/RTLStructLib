DUT = circular_linked_list
SIM_OPTS ?= ../../src/circular_linked_list.sv
SEED ?= 1
TEST ?= all
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE TB_TIMEOUT_CYCLES
SYNTH_PARAMETERS = DATA_WIDTH MAX_NODE

include ../../../Utils/tb/sv/Makefile
