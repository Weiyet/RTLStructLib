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

COMPILE_ARGS = -pfifo.DEPTH=12 # DUT parameter #"-p" iverilog command flags
COMPILE_ARGS += -pfifo.DATA_WIDTH=8 # DUT paramter #"-p" iverilog command flags
COMPILE_ARGS += -pfifo.ASYNC=1 # DUT paramter #"-p" iverilog command flags

include $(shell cocotb-config --makefiles)/Makefile.sim
