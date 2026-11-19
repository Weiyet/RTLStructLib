SEED ?= 123
KEY_WIDTH ?= 32
VALUE_WIDTH ?= 32
TOTAL_INDEX ?= 8
CHAINING_SIZE ?= 4
TB_TIMEOUT_CYCLES ?= 100
PARAMETERS = KEY_WIDTH VALUE_WIDTH TOTAL_INDEX CHAINING_SIZE
RTL_SOURCES ?= $(abspath ../../src/hash_table.sv)
TOPLEVEL = hash_table

include ../../../Utils/tb/cocotb/Makefile
