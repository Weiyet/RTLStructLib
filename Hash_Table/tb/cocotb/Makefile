SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump. 

PWD=$(shell pwd)

#export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(PWD)/../../src/hash_table.sv

# DUT Top
TOPLEVEL = hash_table
# top python file name
MODULE   = tb

#use , separtor to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = index_op_test ， addr_op_test
COMPILE_ARGS = -Phash_table.KEY_WIDTH=32 # DUT parameter #"-p" (parameter) iverilog command flags
COMPILE_ARGS += -Phash_table.VALUE_WIDTH=32 # DUT parameter #"-p" (parameter) iverilog command flags
COMPILE_ARGS += -Phash_table.TOTAL_INDEX=8 # DUT parameter #"-p" (parameter) iverilog command flags
COMPILE_ARGS += -Phash_table.CHAINING_SIZE=4 # DUT parameter #"-p" (parameter) iverilog command flags
#COMPILE_ARGS += -Phash_table.COLLISION_METHOD="MULTI_STAGE_CHAINING" # DUT parameter #"-p" (parameter) iverilog command flags
#COMPILE_ARGS += -Phash_table.HASH_ALGORITHM="MODULUS" # DUT parameter #"-p" (parameter) iverilog command flags
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


