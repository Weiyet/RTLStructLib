TOPLEVEL = list
MODULE = tb_list
RTL_SOURCES ?= $(abspath ../../src/list.sv) $(abspath ../../src/adder.sv) $(abspath ../../src/sorter.sv)
DATA_WIDTH ?= 8
LENGTH ?= 8
SUM_METHOD ?= 0
PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD

include ../../../Utils/vip/pyuvm/Makefile
