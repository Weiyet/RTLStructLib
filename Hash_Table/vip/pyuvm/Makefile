# Makefile for Hash Table pyUVM VIP

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1

PWD=$(shell pwd)

# RTL source files
VERILOG_SOURCES = $(PWD)/../../src/hash_table.sv

TOPLEVEL = hash_table
MODULE   = tb_ht

# DUT parameters
COMPILE_ARGS = -Phash_table.KEY_WIDTH=32
COMPILE_ARGS += -Phash_table.VALUE_WIDTH=32
COMPILE_ARGS += -Phash_table.TOTAL_INDEX=8
COMPILE_ARGS += -Phash_table.CHAINING_SIZE=4
COMPILE_ARGS += -Phash_table.COLLISION_METHOD=\"MULTI_STAGE_CHAINING\"
COMPILE_ARGS += -Phash_table.HASH_ALGORITHM=\"MODULUS\"

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Waveform dump
ifeq ($(SIM), icarus)
ifeq ($(WAVES), 1)
	$(shell echo 'module iverilog_dump();' > iverilog_dump.v)
	$(shell echo 'initial begin' >> iverilog_dump.v)
	$(shell echo '    $$dumpfile("$(TOPLEVEL).vcd");' >> iverilog_dump.v)
	$(shell echo '    $$dumpvars(0, $(TOPLEVEL));' >> iverilog_dump.v)
	$(shell echo 'end' >> iverilog_dump.v)
	$(shell echo 'endmodule' >> iverilog_dump.v)
	VERILOG_SOURCES += $(PWD)/iverilog_dump.v
	COMPILE_ARGS += -s iverilog_dump
endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: help
help:
	@echo "Hash Table pyUVM VIP Makefile"
	@echo "=============================="
	@echo ""
	@echo "Usage:"
	@echo "  make                    - Run all tests with Icarus Verilog"
	@echo "  make WAVES=0            - Disable waveforms"
	@echo "  make clean              - Clean build files"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Run with waves enabled"
	@echo "  make WAVES=0            # Run without waveforms"
