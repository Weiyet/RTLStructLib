SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump. 

PWD=$(shell pwd)

#export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(PWD)/../../src/table.sv

# DUT Top
TOPLEVEL = table_top
# top python file name
MODULE   = tb

#use , separtor to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = lifo_rand_op_test
TESTCASE = table_rand_test

COMPILE_ARGS = -Ptable_top.TABLE_SIZE=32 # DUT parameter #"-p" (parameter) iverilog command flags
COMPILE_ARGS += -Ptable_top.DATA_WIDTH=8 # DUT parameter #"-p" (parameter) iverilog command flags
COMPILE_ARGS += -Ptable_top.INPUT_RATE=1 # DUT parameter #"-p" (parameter) iverilog command flags 
COMPILE_ARGS += -Ptable_top.OUTPUT_RATE=1 # DUT parameter #"-p" (parameter) iverilog command flags 
#run make clean before running with new parameter.

#Set RANDOM_SEED number
#PLUSARGS = +seed=1716033254
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


