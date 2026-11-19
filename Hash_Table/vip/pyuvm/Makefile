TOPLEVEL = hash_table
MODULE = tb_ht
RTL_SOURCES ?= $(abspath ../../src/hash_table.sv)
KEY_WIDTH ?= 32
VALUE_WIDTH ?= 32
TOTAL_INDEX ?= 8
CHAINING_SIZE ?= 4
PARAMETERS = KEY_WIDTH VALUE_WIDTH TOTAL_INDEX CHAINING_SIZE

include ../../../Utils/vip/pyuvm/Makefile
