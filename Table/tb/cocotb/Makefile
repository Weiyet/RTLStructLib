SEED ?= 123
DATA_WIDTH ?= 8
TABLE_SIZE ?= 32
INPUT_RATE ?= 2
OUTPUT_RATE ?= 2
TB_TIMEOUT_CYCLES ?= 20000
PARAMETERS = DATA_WIDTH TABLE_SIZE INPUT_RATE OUTPUT_RATE
RTL_SOURCES ?= $(abspath ../../src/table.sv)
TOPLEVEL = table_top

include ../../../Utils/tb/cocotb/Makefile
