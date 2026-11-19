TOPLEVEL = fifo
MODULE = tb_fifo
RTL_SOURCES ?= $(abspath ../../src/fifo.sv)
DEPTH ?= 16
DATA_WIDTH ?= 8
ASYNC ?= 1
RD_BUFFER ?= 1
PARAMETERS = DEPTH DATA_WIDTH ASYNC RD_BUFFER

include ../../../Utils/vip/pyuvm/Makefile
