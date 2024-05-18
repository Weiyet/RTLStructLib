SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump. 

PWD=$(shell pwd)

#export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(PWD)/../../src/fifo.sv

TOPLEVEL = fifo  # DUT Top
MODULE   = tb  # top python file

#use , separtor to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = fifo_rand_read_write_test,fifo_rand_write_then_read_test,fifo_rand_read_write_simul_test
#TESTCASE = fifo_rand_read_write_simul_test

COMPILE_ARGS = -Pfifo.DEPTH=12 # DUT parameter #"-p" iverilog command flags
COMPILE_ARGS += -Pfifo.DATA_WIDTH=8 # DUT parameter #"-p" iverilog command flags
COMPILE_ARGS += -Pfifo.ASYNC=1 # DUT paramter #"-p" iverilog command flags
COMPILE_ARGS += -Pfifo.RD_BUFFER=1 # DUT paramter #"-p" iverilog command flags
#run make clean before running with new parameter.

#Set RANDOM_SEED number
#PLUSARGS = +seed=1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

ifeq ($(SIM), icarus) 
   $(shell echo 'module iverilog_dump();' > iverilog_dump.v)
   $(shell echo 'initial begin' >> iverilog_dump.v)
   $(shell echo '    $$dumpfile("$(TOPLEVEL).vcd");' >> iverilog_dump.v)
   $(shell echo '    $$dumpvars(0, $(TOPLEVEL));' >> iverilog_dump.v)
   $(shell echo '    $$dumpvars(0, $(TOPLEVEL));' >> iverilog_dump.v)
   $(shell echo 'end' >> iverilog_dump.v)
   $(shell echo 'endmodule' >> iverilog_dump.v)
   VERILOG_SOURCES += $(PWD)/iverilog_dump.v
   COMPILE_ARGS += -s iverilog_dump  
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
