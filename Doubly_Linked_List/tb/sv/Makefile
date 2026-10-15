SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.PHONY: sim gen_sim synth netlist_sim clean
YOSYS_DATDIR ?= /usr/share/yosys
DUT = doubly_linked_list
SIM_OPTS ?= ../../src/doubly_linked_list.sv
SEED ?= 1
TEST ?= all
WAVES ?= 0
SIM_BUILD ?= sim_build
DATA_WIDTH ?= 8
MAX_NODE ?= 8
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH MAX_NODE TB_TIMEOUT_CYCLES
PARAM_ARGS = $(foreach param,$(PARAMETERS),-Ptb.$(param)=$($(param)))
ifeq ($(WAVES),1)
WAVE_ARGS = +VCDFILE=$(SIM_BUILD)/sim.vcd
endif
sim: gen_sim
	vvp $(SIM_BUILD)/$(DUT).sim +SEED=$(SEED) +TEST=$(TEST) $(WAVE_ARGS) | tee $(SIM_BUILD)/sim.log
gen_sim: tb.sv ../../../Utils/tb/linked_list/linked_list_tb.svh $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	iverilog -g2012 -I../../../Utils/tb/linked_list -s tb $(PARAM_ARGS) $(COMPILE_ARGS) -o $(SIM_BUILD)/$(DUT).sim tb.sv $(SIM_OPTS)
synth: $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	yosys -q -p 'read_verilog -sv $(SIM_OPTS); chparam -set DATA_WIDTH $(DATA_WIDTH) -set MAX_NODE $(MAX_NODE) $(DUT); hierarchy -top $(DUT); proc; check -assert; select -assert-none t:$$dlatch t:$$adlatch; synth_xilinx -top $(DUT); check -assert; select -assert-none t:LDCE t:LDPE' -L $(SIM_BUILD)/synth.log -o $(SIM_BUILD)/$(DUT).netlist.v
ifeq ($(SKIP_SYNTH),1)
netlist_sim: $(SIM_BUILD)/$(DUT).netlist.v
else
netlist_sim: synth
endif
	iverilog -g2012 -I../../../Utils/tb/linked_list -DLINKED_LIST_NETLIST -s tb $(PARAM_ARGS) -o $(SIM_BUILD)/$(DUT).netlist.sim tb.sv $(SIM_BUILD)/$(DUT).netlist.v $(YOSYS_DATDIR)/xilinx/cells_sim.v
	vvp $(SIM_BUILD)/$(DUT).netlist.sim +SEED=$(SEED) +TEST=$(TEST) | tee $(SIM_BUILD)/netlist_sim.log
clean:
	rm -f $(SIM_BUILD)/$(DUT).sim $(SIM_BUILD)/sim.log $(SIM_BUILD)/sim.vcd
	rm -f $(SIM_BUILD)/$(DUT).netlist.v $(SIM_BUILD)/synth.log
	rm -f $(SIM_BUILD)/$(DUT).netlist.sim $(SIM_BUILD)/netlist_sim.log
