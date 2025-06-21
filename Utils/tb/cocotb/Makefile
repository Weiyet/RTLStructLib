SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump. 

PWD=$(shell pwd)

#export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)
SRC_DIR ?= $(PWD)/../../src
VERILOG_SOURCES ?= $(addprefix $(SRC_DIR)/, $(shell cat $(SRC_DIR)/rtl_src.f))


# DUT Top
TOPLEVEL = list
# top python file name
MODULE   = tb

#use , separtor to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = index_op_test ， addr_op_test

COMPILE_ARGS ?= -P list.DATA_WIDTH=8 
COMPILE_ARGS += -P list.LENGTH=8 
COMPILE_ARGS += -P list.SUM_METHOD=0 
#"-P" (parameter) iverilog command flags
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


