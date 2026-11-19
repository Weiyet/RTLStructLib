DUT = list
SIM_OPTS ?= ../../src/list.sv ../../src/adder.sv ../../src/sorter.sv
SEED ?= 1
TEST ?= all
DATA_WIDTH ?= 8
LENGTH ?= 8
SUM_METHOD ?= 0
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD TB_TIMEOUT_CYCLES
SYNTH_PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD

include ../../../Utils/tb/sv/Makefile
