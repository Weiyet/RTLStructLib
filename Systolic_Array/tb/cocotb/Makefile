SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump.

PWD=$(shell pwd)

VERILOG_SOURCES = $(PWD)/../../src/pe.sv
VERILOG_SOURCES += $(PWD)/../../src/systolic_array.sv
VERILOG_SOURCES += $(PWD)/../../src/systolic_array_top.sv

TOPLEVEL = systolic_array_top  # DUT Top
MODULE   = tb  # top python file

# Use , separator to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = test_simple_values,test_identity_matrix,test_random_matrices
#TESTCASE = test_simple_values

# DUT parameters - use "-p" iverilog command flags
COMPILE_ARGS = -Psystolic_array_top.ARRAY_ROWS=4
COMPILE_ARGS += -Psystolic_array_top.ARRAY_COLS=4
COMPILE_ARGS += -Psystolic_array_top.K_DIM=4
COMPILE_ARGS += -Psystolic_array_top.DATA_WIDTH=8
COMPILE_ARGS += -Psystolic_array_top.WEIGHT_WIDTH=8
COMPILE_ARGS += -Psystolic_array_top.ACC_WIDTH=32
COMPILE_ARGS += -Psystolic_array_top.SIGNED_MATH=1
COMPILE_ARGS += -Psystolic_array_top.INPUT_SKEW=1
# Run make clean before running with new parameters.

# Set RANDOM_SEED number
#PLUSARGS = +seed=1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

ifeq ($(SIM), icarus)
   $(shell echo 'module iverilog_dump();' > iverilog_dump.v)
   $(shell echo 'initial begin' >> iverilog_dump.v)
   $(shell echo '    $$dumpfile("$(TOPLEVEL).vcd");' >> iverilog_dump.v)
   $(shell echo '    $$dumpvars(0, $(TOPLEVEL));' >> iverilog_dump.v)
   $(shell echo 'end' >> iverilog_dump.v)
   $(shell echo 'endmodule' >> iverilog_dump.v)
   VERILOG_SOURCES += $(PWD)/iverilog_dump.v
   COMPILE_ARGS += -s iverilog_dump
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
