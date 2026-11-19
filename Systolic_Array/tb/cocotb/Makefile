SEED ?= 1
TB_TIMEOUT_CYCLES ?= 1000
ARRAY_ROWS ?= 4
ARRAY_COLS ?= 4
K_DIM ?= 4
DATA_WIDTH ?= 8
WEIGHT_WIDTH ?= 8
ACC_WIDTH ?= 32
SIGNED_MATH ?= 1
INPUT_SKEW ?= 1
PARAMETERS = ARRAY_ROWS ARRAY_COLS K_DIM DATA_WIDTH WEIGHT_WIDTH ACC_WIDTH SIGNED_MATH INPUT_SKEW
RTL_SOURCES ?= $(abspath ../../src/pe.sv) $(abspath ../../src/systolic_array.sv) $(abspath ../../src/systolic_array_top.sv)
TOPLEVEL = systolic_array_top

include ../../../Utils/tb/cocotb/Makefile
