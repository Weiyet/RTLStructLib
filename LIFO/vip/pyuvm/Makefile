# Makefile for LIFO pyUVM VIP

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1

PWD=$(shell pwd)

# RTL source files
VERILOG_SOURCES = $(PWD)/../../src/lifo.sv

TOPLEVEL = lifo
MODULE   = tb_lifo

# DUT parameters
COMPILE_ARGS = -Plifo.DEPTH=12
COMPILE_ARGS += -Plifo.DATA_WIDTH=8

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
	@echo "LIFO pyUVM VIP Makefile"
	@echo "======================="
	@echo ""
	@echo "Usage:"
	@echo "  make           - Run test with Icarus Verilog"
	@echo "  make WAVES=0   - Disable waveforms"
	@echo "  make clean     - Clean build files"
