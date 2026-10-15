SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.PHONY: sim gen_sim synth clean
DUT = list
SIM_OPTS ?= ../../src/list.sv ../../src/adder.sv ../../src/sorter.sv
SEED ?= 1
TEST ?= all
WAVES ?= 0
SIM_BUILD ?= sim_build
DATA_WIDTH ?= 8
LENGTH ?= 8
SUM_METHOD ?= 0
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = DATA_WIDTH LENGTH SUM_METHOD TB_TIMEOUT_CYCLES
PARAM_ARGS = $(foreach param,$(PARAMETERS),-Ptb.$(param)=$($(param)))
ifeq ($(WAVES),1)
WAVE_ARGS = +VCDFILE=$(SIM_BUILD)/sim.vcd
endif

sim: gen_sim
	vvp $(SIM_BUILD)/$(DUT).sim +SEED=$(SEED) +TEST=$(TEST) $(WAVE_ARGS) | tee $(SIM_BUILD)/sim.log

gen_sim: tb.sv $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb $(PARAM_ARGS) $(COMPILE_ARGS) -o $(SIM_BUILD)/$(DUT).sim $^

synth: $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	yosys -q -p 'read_verilog -sv $(SIM_OPTS); chparam -set DATA_WIDTH $(DATA_WIDTH) -set LENGTH $(LENGTH) -set SUM_METHOD $(SUM_METHOD) list; hierarchy -top list; proc; check -assert; select -assert-none t:$$dlatch t:$$adlatch; synth_xilinx -top list; check -assert; select -assert-none t:LDCE t:LDPE' -L $(SIM_BUILD)/synth.log -o $(SIM_BUILD)/$(DUT).netlist.v

clean:
	rm -f $(SIM_BUILD)/$(DUT).sim $(SIM_BUILD)/sim.log $(SIM_BUILD)/sim.vcd
	rm -f $(SIM_BUILD)/$(DUT).netlist.v $(SIM_BUILD)/synth.log
	rm -f $(DUT).sim sim.log sim.vcd $(DUT).netlist.v synth.log
