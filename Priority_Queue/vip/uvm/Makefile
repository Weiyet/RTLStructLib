SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := sim
.PHONY: sim compile lint
DEPTH ?= 16
PRIORITY_WIDTH ?= 8
DATA_WIDTH ?= 8
MIN_FIRST ?= 1
SEED ?= 123
TB_TIMEOUT_CYCLES ?= 100000
TEST ?= priority_vip_boundary_test
SIM_BUILD ?= sim_build
# Questa with its bundled/precompiled UVM library; override for your installation.
UVM_LIB ?= uvm
VERILATOR ?= verilator
UVM_INCDIR ?= $(UVM_HOME)/src
PARAMETERS = DEPTH PRIORITY_WIDTH DATA_WIDTH MIN_FIRST
DEFINES = $(foreach param,$(PARAMETERS),+define+PQ_VIP_$(param)=$($(param)))
compile:
	test -f "$(UVM_INCDIR)/uvm_macros.svh" || { echo 'Set UVM_INCDIR to the UVM source include directory'; exit 1; }
	mkdir -p $(SIM_BUILD)
	if [ ! -d $(SIM_BUILD)/work ]; then vlib $(SIM_BUILD)/work; fi
	vlog -sv -work $(SIM_BUILD)/work -L $(UVM_LIB) +incdir+$(UVM_INCDIR) $(DEFINES) -f files.f | tee $(SIM_BUILD)/compile.log
sim: compile
	rm -f $(SIM_BUILD)/sim.log
	vsim -c -lib $(SIM_BUILD)/work -L $(UVM_LIB) tb_top -sv_seed $(SEED) +UVM_TESTNAME=$(TEST) +TB_TIMEOUT_CYCLES=$(TB_TIMEOUT_CYCLES) -do 'onerror {quit -code 1}; run -all; quit -code 0' | tee $(SIM_BUILD)/sim.log
	python3 sim/check_uvm_log.py $(SIM_BUILD)/sim.log

# Check SV UVM only; use Verilator 5.054 or newer.
lint:
	test -f "$(UVM_INCDIR)/uvm_pkg.sv" || { echo 'Set UVM_HOME or UVM_INCDIR to the UVM source directory'; exit 1; }
	mkdir -p $(SIM_BUILD)
	$(VERILATOR) --lint-only --timing -Wno-fatal --top-module tb_top --Mdir "$(SIM_BUILD)/lint" -I"$(UVM_INCDIR)" "$(UVM_INCDIR)/uvm_pkg.sv" $(DEFINES) -f files.f 2>&1 | tee $(SIM_BUILD)/lint.log
