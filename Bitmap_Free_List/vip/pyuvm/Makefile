TOPLEVEL = bitmap_free_list
MODULE = tb_bitmap
RTL_SOURCES ?= $(abspath ../../src/bitmap_free_list.sv)
CAPACITY ?= 16
SEED ?= 123
TB_TIMEOUT_CYCLES ?= 20000
PARAMETERS = CAPACITY

include ../../../Utils/vip/pyuvm/Makefile
