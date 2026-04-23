# FIFO VIP Verilator Makefile
# Create Date: 2026-04-23

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
TOP_MODULE  = fifo
RTL_DIR     = ../../src
TB_DIR      = .
OBJ_DIR     = obj_dir

# Verilator flags
VERILATOR   = verilator
VFLAGS      = --cc --exe --build
VFLAGS     += --trace              # Enable VCD waveform generation
VFLAGS     += -Wall                # Enable all warnings
VFLAGS     += -Wno-fatal           # Don't stop on warnings
VFLAGS     += --x-assign unique    # Randomize X assignments
VFLAGS     += --x-initial unique   # Randomize initial X values
VFLAGS     += -I$(RTL_DIR)         # Include path for RTL

# C++ flags
CXXFLAGS    = -std=c++17 -O2
CXXFLAGS   += -I$(TB_DIR)

# Source files
RTL_SRCS    = $(RTL_DIR)/$(TOP_MODULE).sv
TB_SRCS     = $(TB_DIR)/fifo_tb.cpp

# Output executable
TARGET      = $(OBJ_DIR)/V$(TOP_MODULE)

#------------------------------------------------------------------------------
# Default target
#------------------------------------------------------------------------------
.PHONY: all
all: $(TARGET)

#------------------------------------------------------------------------------
# Build
#------------------------------------------------------------------------------
$(TARGET): $(RTL_SRCS) $(TB_SRCS)
	$(VERILATOR) $(VFLAGS) \
		-CFLAGS "$(CXXFLAGS)" \
		--top-module $(TOP_MODULE) \
		$(RTL_SRCS) \
		$(TB_SRCS)

#------------------------------------------------------------------------------
# Run simulation
#------------------------------------------------------------------------------
.PHONY: run
run: $(TARGET)
	./$(TARGET)

.PHONY: run-verbose
run-verbose: $(TARGET)
	./$(TARGET) --verbose

.PHONY: run-nowaves
run-nowaves: $(TARGET)
	./$(TARGET) --no-waves

#------------------------------------------------------------------------------
# View waveforms
#------------------------------------------------------------------------------
.PHONY: waves
waves: run
	gtkwave fifo_tb.vcd &

#------------------------------------------------------------------------------
# Clean
#------------------------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf $(OBJ_DIR)
	rm -f fifo_tb.vcd
	rm -f *.log

.PHONY: cleanall
cleanall: clean

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
.PHONY: help
help:
	@echo "FIFO VIP Verilator Testbench"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build the simulation (default)"
	@echo "  run          - Run simulation"
	@echo "  run-verbose  - Run simulation with verbose output"
	@echo "  run-nowaves  - Run simulation without waveform generation"
	@echo "  waves        - Run and view waveforms in GTKWave"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Runtime options (pass to executable):"
	@echo "  -v, --verbose     Enable verbose output"
	@echo "  --no-waves        Disable VCD waveform generation"
	@echo "  --seed=N          Set random seed"
	@echo "  --writes=N        Set number of write transactions"
	@echo "  --reads=N         Set number of read transactions"
