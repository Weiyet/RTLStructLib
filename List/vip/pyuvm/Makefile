# Makefile for List pyUVM VIP

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1  # Set 1 to enable waveform dump

PWD=$(shell pwd)

# RTL source files
VERILOG_SOURCES = $(PWD)/../../src/list.sv
VERILOG_SOURCES += $(PWD)/../../src/sort.sv
VERILOG_SOURCES += $(PWD)/../../src/adder.sv

TOPLEVEL = list  # DUT Top
MODULE   = tb_list  # Top Python file (without .py)

# DUT parameters - passed to simulator
COMPILE_ARGS = -Plist.DATA_WIDTH=8
COMPILE_ARGS += -Plist.LENGTH=8
COMPILE_ARGS += -Plist.SUM_METHOD=0

# Set RANDOM_SEED number (optional)
#PLUSARGS = +seed=42

# Time units
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Icarus Verilog waveform dump
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

# Include cocotb Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Additional targets
.PHONY: help
help:
	@echo "List pyUVM VIP Makefile"
	@echo "======================="
	@echo ""
	@echo "Usage:"
	@echo "  make                    - Run all tests with Icarus Verilog"
	@echo "  make WAVES=0            - Disable waveforms"
	@echo "  make clean              - Clean build files"
	@echo ""
	@echo "Environment Variables:"
	@echo "  WAVES      - Enable waveforms (0/1)"
	@echo "  PLUSARGS   - Additional simulator arguments"
	@echo ""
	@echo "Examples:"
	@echo "  make                               # Run with icarus, waves enabled"
	@echo "  make WAVES=0                       # Run without waveforms (faster)"
	@echo "  make PLUSARGS=+seed=123            # Run with specific seed"
