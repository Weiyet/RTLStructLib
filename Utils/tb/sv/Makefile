# Include after the block's source, parameter and optional netlist settings.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := sim
.PHONY: sim gen_sim synth netlist_sim gen_netlist_sim clean help check-synth-library check-gls-library

IVERILOG ?= iverilog
VVP ?= vvp
YOSYS ?= yosys
YOSYS_DATDIR ?= /usr/share/yosys
TB_TOP ?= tb
TB_SOURCES ?= tb.sv
SYNTH_TOP ?= $(DUT)
SEED ?= 123
WAVES ?= 0
TECH ?= xilinx
SIM_BUILD ?= $(if $(filter sky130,$(TECH)),sim_build/sky130,sim_build)
SYNTH_LOG ?= $(SIM_BUILD)/synth.log
NETLIST ?= $(SIM_BUILD)/$(DUT).netlist.v
SYNTH_FORBIDDEN_CELLS ?= t:$$dlatch t:$$adlatch

# SKY130 paths follow the open_pdks/Volare installation layout. The library is external.
PDK ?= sky130A
SKY130_CORNER ?= tt_025C_1v80
SKY130_LIB_DIR ?= $(PDK_ROOT)/$(PDK)/libs.ref/sky130_fd_sc_hd
SKY130_LIBERTY ?= $(SKY130_LIB_DIR)/lib/sky130_fd_sc_hd__$(SKY130_CORNER).lib
SKY130_MODELS ?= $(SKY130_LIB_DIR)/verilog/primitives.v $(SKY130_LIB_DIR)/verilog/sky130_fd_sc_hd.v

ifeq ($(TECH),xilinx)
SYNTH_READ_LIB =
SYNTH_MAP = synth_xilinx -top $(SYNTH_TOP); check -assert; select -assert-none t:LDCE t:LDPE
GLS_MODELS = $(YOSYS_DATDIR)/xilinx/cells_sim.v
GLS_FLAGS =
check-synth-library:
	@:
else ifeq ($(TECH),sky130)
SYNTH_READ_LIB = read_liberty -lib -ignore_miss_func "$(SKY130_LIBERTY)";
SYNTH_MAP = synth -top $(SYNTH_TOP) -noabc; \
    dfflibmap -liberty "$(SKY130_LIBERTY)"; \
    abc -liberty "$(SKY130_LIBERTY)"; \
    hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO; \
    clean; check -assert; select -assert-none t:$$*; stat -liberty "$(SKY130_LIBERTY)"
GLS_MODELS = $(SKY130_MODELS)
GLS_FLAGS = -DFUNCTIONAL -DUNIT_DELAY=
check-synth-library:
	@test -f "$(SKY130_LIBERTY)" || { echo 'Missing SKY130 Liberty: $(SKY130_LIBERTY). Set PDK_ROOT or SKY130_LIBERTY.' >&2; exit 2; }
else
$(error Unsupported TECH=$(TECH); use xilinx or sky130)
endif

check-gls-library:
	@test -n "$(strip $(GLS_MODELS))" || { echo 'No GLS cell models configured' >&2; exit 2; }
	@for model in $(GLS_MODELS); do test -f "$$model" || { echo "Missing GLS cell model: $$model" >&2; exit 2; }; done

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

synth: check-synth-library $(SIM_OPTS)
	mkdir -p $(SIM_BUILD)
	$(YOSYS) -q -p '$(SYNTH_READ_LIB) read_verilog -sv $(SIM_OPTS); $(if $(strip $(SYNTH_PARAMETERS)),chparam $(SYNTH_ARGS) $(SYNTH_TOP);) hierarchy -top $(SYNTH_TOP); proc; check -assert; select -assert-none $(SYNTH_FORBIDDEN_CELLS); $(SYNTH_MAP)' -L $(SYNTH_LOG) -o $(NETLIST)

# Opt in only when the TB supports a parameter-free mapped DUT instance.
ifneq ($(strip $(NETLIST_DEFINE)),)
ifeq ($(SKIP_SYNTH),1)
gen_netlist_sim: $(NETLIST)
else
gen_netlist_sim: synth
endif
gen_netlist_sim: check-gls-library $(TB_SOURCES) $(TB_HEADERS)
	mkdir -p $(SIM_BUILD)
	$(IVERILOG) -g2012 $(INCLUDE_ARGS) -D$(NETLIST_DEFINE) -s $(TB_TOP) $(PARAM_ARGS) $(COMPILE_ARGS) $(GLS_FLAGS) -o $(SIM_BUILD)/$(DUT).netlist.sim $(TB_SOURCES) $(NETLIST) $(GLS_MODELS)

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
	@echo 'TECH=xilinx (default) or sky130; SKY130 requires PDK_ROOT or explicit SKY130_LIBERTY/SKY130_MODELS.'
	@echo 'SKY130_CORNER=tt_025C_1v80 by default. GLS is functional, without SDF.'
	@echo 'Use SKIP_SYNTH=1 only with a netlist synthesized for the same RTL, technology and parameters.'
