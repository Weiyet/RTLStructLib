# Makefile for Table pyUVM VIP

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1

PWD=$(shell pwd)

# RTL source files
VERILOG_SOURCES = $(PWD)/../../src/table.sv

TOPLEVEL = table_top
MODULE   = tb_table

# DUT parameters
COMPILE_ARGS = -Ptable_top.TABLE_SIZE=32
COMPILE_ARGS += -Ptable_top.DATA_WIDTH=8
COMPILE_ARGS += -Ptable_top.INPUT_RATE=2
COMPILE_ARGS += -Ptable_top.OUTPUT_RATE=2

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
	@echo "Table pyUVM VIP Makefile"
	@echo "========================"
	@echo ""
	@echo "Usage:"
	@echo "  make           - Run test with Icarus Verilog"
	@echo "  make WAVES=0   - Disable waveforms"
	@echo "  make clean     - Clean build files"
