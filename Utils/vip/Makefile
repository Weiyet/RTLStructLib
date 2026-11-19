# Include from a block's vip/uvm/Makefile. Paths are relative to that bench.
# Set TEST, DEFINES, PLUSARGS and CHECK_LOG (command accepting a log filename).
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := sim
.PHONY: sim compile run lint check-tools

VERILATOR ?= verilator
UVM_INCDIR ?= $(UVM_HOME)/src
UVM_DPI ?= $(UVM_INCDIR)/dpi/uvm_dpi.cc
TOP ?= tb_top
FILELIST ?= files.f
SIM_BUILD ?= sim_build
SEED ?= 123
JOBS ?= 2
CXX_OPT ?= -O0
SIM_TIMEOUT ?= 120
VERILATOR_FLAGS ?=

check-tools:
	@$(VERILATOR) --version | awk '$$1 == "Verilator" { split($$2, v, "."); ok = v[1] > 5 || (v[1] == 5 && v[2] >= 54) } END { exit !ok }' || { echo 'Use Verilator 5.054 or newer'; exit 1; }
	@test -f "$(UVM_INCDIR)/uvm_pkg.sv" || { echo 'Set UVM_HOME or UVM_INCDIR to the UVM source directory'; exit 1; }

compile: check-tools
	test -f "$(UVM_DPI)" || { echo 'Set UVM_DPI to the Verilator-compatible UVM DPI source'; exit 1; }
	mkdir -p "$(SIM_BUILD)"
	$(VERILATOR) --binary --timing --assert --vpi -Wno-fatal -j $(JOBS) \
		--top-module $(TOP) --Mdir "$(abspath $(SIM_BUILD))/obj_dir" -o sim_uvm \
		-I"$(UVM_INCDIR)" "$(UVM_INCDIR)/uvm_pkg.sv" "$(abspath $(UVM_DPI))" \
		$(DEFINES) -f "$(FILELIST)" -MAKEFLAGS "OPT_FAST=$(CXX_OPT)" $(VERILATOR_FLAGS) \
		2>&1 | tee "$(SIM_BUILD)/compile.log"

# sim always checks/rebuilds the sources; run reuses the existing executable.
sim: compile
sim run:
	test -n "$(TEST)" || { echo 'Set TEST to a registered UVM test'; exit 1; }
	test -n "$(CHECK_LOG)" || { echo 'Set CHECK_LOG to the bench completion/error checker'; exit 1; }
	test -x "$(abspath $(SIM_BUILD))/obj_dir/sim_uvm" || { echo 'Run make compile before make run'; exit 1; }
	timeout $(SIM_TIMEOUT) "$(abspath $(SIM_BUILD))/obj_dir/sim_uvm" \
		+verilator+seed+$(SEED) +UVM_TESTNAME=$(TEST) $(PLUSARGS) 2>&1 | tee "$(SIM_BUILD)/sim.log"
	$(CHECK_LOG) "$(SIM_BUILD)/sim.log"

lint: check-tools
	mkdir -p "$(SIM_BUILD)"
	$(VERILATOR) --lint-only --timing --assert -Wno-fatal --top-module $(TOP) \
		--Mdir "$(abspath $(SIM_BUILD))/lint" -I"$(UVM_INCDIR)" "$(UVM_INCDIR)/uvm_pkg.sv" \
		$(DEFINES) -f "$(FILELIST)" $(VERILATOR_FLAGS) 2>&1 | tee "$(SIM_BUILD)/lint.log"
