SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.PHONY: sim gen_sim synth netlist_sim gen_netlist_sim clean

DUT = systolic_array
SIM_OPTS ?= ../../src/pe.sv ../../src/systolic_array.sv ../../src/systolic_array_top.sv
SEED ?= 1
TEST ?= all
WAVES ?= 0
SIM_BUILD ?= sim_build
ARRAY_ROWS ?= 4
ARRAY_COLS ?= 4
K_DIM ?= 4
DATA_WIDTH ?= 8
WEIGHT_WIDTH ?= 8
ACC_WIDTH ?= 32
SIGNED_MATH ?= 1
INPUT_SKEW ?= 1
TB_TIMEOUT_CYCLES ?= 1000
PARAMETERS = ARRAY_ROWS ARRAY_COLS K_DIM DATA_WIDTH WEIGHT_WIDTH ACC_WIDTH SIGNED_MATH INPUT_SKEW TB_TIMEOUT_CYCLES
PARAM_ARGS = $(foreach param,$(PARAMETERS),-Ptb.$(param)=$($(param)))
ifeq ($(WAVES),1)
WAVE_ARGS = +VCDFILE=$(SIM_BUILD)/sim.vcd
endif
XILINX_LIB_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_LIB_DIR ?= XilinxUnisimLibrary/verilog/src

sim: gen_sim
	vvp $(SIM_BUILD)/$(DUT).sim +SEED=$(SEED) +TEST=$(TEST) $(WAVE_ARGS) | tee $(SIM_BUILD)/sim.log

gen_sim: tb.sv ${SIM_OPTS}
	mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb $(PARAM_ARGS) $(COMPILE_ARGS) -o $(SIM_BUILD)/$(DUT).sim $^

synth: ${SIM_OPTS}
	yosys -p synth_xilinx ${SIM_OPTS} -L synth.log -o ${DUT}.netlist.v

netlist_sim: gen_netlist_sim
	./${DUT}.netlist.sim +VCDFILE=netlist_sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee netlist_sim.log

gen_netlist_sim: tb.sv ${DUT}.netlist.v | ${XILINX_LIB_DIR}/.git
	iverilog -g2012 -DXILINX_GLS -s tb -y ${XILINX_LIB_DIR} -y ${XILINX_LIB_DIR}/unisims -DXILINX_GLS -o ${DUT}.netlist.sim tb.sv ${DUT}.netlist.v

${XILINX_LIB_DIR}/.git:
	git clone ${XILINX_LIB_URL}

clean:
	rm -f $(SIM_BUILD)/$(DUT).sim $(SIM_BUILD)/sim.log $(SIM_BUILD)/sim.vcd
	rm -f ${DUT}.sim sim.log sim.vcd
	rm -f ${DUT}.netlist.v synth.log
	rm -f ${DUT}.netlist.sim netlist_sim.log netlist_sim.vcd
