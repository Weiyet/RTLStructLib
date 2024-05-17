SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1 #set 1 to enable waveform dump. 

PWD=$(shell pwd)

#export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(PWD)/../../src/lifo.sv

TOPLEVEL = lifo  # DUT Top
MODULE   = tb  # top python file

#use , separtor to run multiple TESTCASE, by default all @cocotb.test will be run
#TESTCASE = lifo_rand_op_test
TESTCASE = lifo_rand_op_test

COMPILE_ARGS = -Plifo.DEPTH=12 # DUT parameter #"-p" iverilog command flags
COMPILE_ARGS += -Plifo.DATA_WIDTH=8 # DUT parameter #"-p" iverilog command flags
#run make clean before running with new parameter.

#Set RANDOM_SEED number
#PLUSARGS = +seed=1

include $(shell cocotb-config --makefiles)/Makefile.sim
