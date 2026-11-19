# Include after the block's source, parameter and optional netlist settings.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := sim
.PHONY: sim gen_sim synth netlist_sim gen_netlist_sim clean help

IVERILOG ?= iverilog
VVP ?= vvp
YOSYS ?= yosys
YOSYS_DATDIR ?= /usr/share/yosys
TB_TOP ?= tb
TB_SOURCES ?= tb.sv
SYNTH_TOP ?= $(DUT)
SEED ?= 123
WAVES ?= 0
SIM_BUILD ?= sim_build
SYNTH_LOG ?= $(SIM_BUILD)/synth.log
NETLIST ?= $(SIM_BUILD)/$(DUT).netlist.v
SYNTH_FORBIDDEN_CELLS ?= t:$$dlatch t:$$adlatch

PARAM_ARGS = $(foreach param,$(PARAMETERS),-P$(TB_TOP).$(param)=$($(param)))
SYNTH_ARGS = $(foreach param,$(SYNTH_PARAMETERS),-set $(param) $($(param)))
INCLUDE_ARGS = $(addprefix -I,$(TB_INCLUDE_DIRS))
RUN_ARGS = +SEED=$(SEED) $(if $(TEST),+TEST=$(TEST)) $(PLUSARGS)
ifeq ($(WAVES),1)
WAVE_ARGS = +VCDFILE=$(SIM_BUILD)/sim.vcd +VCDLEVEL=0
NETLIST_WAVE_ARGS = +VCDFILE=$(SIM_BUILD)/netlist_sim.vcd +VCDLEVEL=0
endif

sim: gen_sim
	$(VVP) $(SIM_BUILD)/$(DUT).sim $(RUN_ARGS) $(WAVE_ARGS) | tee $(SIM_BUILD)/sim.log

gen_sim: $(TB_SOURCES) $(TB_HEADERS) $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	$(IVERILOG) -g2012 $(INCLUDE_ARGS) -s $(TB_TOP) $(PARAM_ARGS) $(COMPILE_ARGS) -o $(SIM_BUILD)/$(DUT).sim $(TB_SOURCES) $(SIM_OPTS)

synth: $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	$(YOSYS) -q -p 'read_verilog -sv $(SIM_OPTS); $(if $(strip $(SYNTH_PARAMETERS)),chparam $(SYNTH_ARGS) $(SYNTH_TOP);) hierarchy -top $(SYNTH_TOP); proc; check -assert; select -assert-none $(SYNTH_FORBIDDEN_CELLS); synth_xilinx -top $(SYNTH_TOP); check -assert; select -assert-none t:LDCE t:LDPE' -L $(SYNTH_LOG) -o $(NETLIST)

# Opt in only when the TB supports a parameter-free mapped DUT instance.
ifneq ($(strip $(NETLIST_DEFINE)),)
ifeq ($(SKIP_SYNTH),1)
gen_netlist_sim: $(NETLIST)
else
gen_netlist_sim: synth
endif
gen_netlist_sim: $(TB_SOURCES) $(TB_HEADERS)
	mkdir -p $(SIM_BUILD)
	$(IVERILOG) -g2012 $(INCLUDE_ARGS) -D$(NETLIST_DEFINE) -s $(TB_TOP) $(PARAM_ARGS) $(COMPILE_ARGS) -o $(SIM_BUILD)/$(DUT).netlist.sim $(TB_SOURCES) $(NETLIST) $(YOSYS_DATDIR)/xilinx/cells_sim.v

netlist_sim: gen_netlist_sim
	$(VVP) $(SIM_BUILD)/$(DUT).netlist.sim $(RUN_ARGS) $(NETLIST_WAVE_ARGS) | tee $(SIM_BUILD)/netlist_sim.log
else
netlist_sim gen_netlist_sim:
	@echo 'Mapped-netlist simulation is not supported by this testbench.' >&2
	@exit 2
endif

clean:
	rm -f $(SIM_BUILD)/$(DUT).sim $(SIM_BUILD)/sim.log $(SIM_BUILD)/sim.vcd
	rm -f $(NETLIST) $(SYNTH_LOG) $(SIM_BUILD)/$(DUT).netlist.sim $(SIM_BUILD)/netlist_sim.log $(SIM_BUILD)/netlist_sim.vcd

help:
	@echo 'Targets: sim (default), gen_sim, synth, netlist_sim (where supported), clean'
	@echo 'Options: SEED=123 WAVES=1 SIM_BUILD=sim_build; block parameters are in the local Makefile.'
	@echo 'Use SKIP_SYNTH=1 only with a netlist synthesized for the same parameters.'
