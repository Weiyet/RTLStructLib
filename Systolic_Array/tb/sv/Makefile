DUT = systolic_array
SIM_OPTS ?= ../../src/pe.sv ../../src/systolic_array.sv ../../src/systolic_array_top.sv
SEED ?= $$(shuf -i 1-10000 -n 1)
XILINX_LIB_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_LIB_DIR ?= XilinxUnisimLibrary/verilog/src

sim: gen_sim
	./${DUT}.sim +VCDFILE=sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee sim.log

gen_sim: tb.sv ${SIM_OPTS}  # to generate executable file by using iverilog
	iverilog -g2012 -s tb -o ${DUT}.sim $^

synth: ${SIM_OPTS}
	yosys -p synth_xilinx ${SIM_OPTS} -L synth.log -o ${DUT}.netlist.v

netlist_sim: gen_netlist_sim
	./${DUT}.netlist.sim +VCDFILE=netlist_sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee netlist_sim.log

gen_netlist_sim: tb.sv ${DUT}.netlist.v | ${XILINX_LIB_DIR}/.git
	iverilog -g2012 -DXILINX_GLS -s tb -y ${XILINX_LIB_DIR} -y ${XILINX_LIB_DIR}/unisims -DXILINX_GLS -o ${DUT}.netlist.sim tb.sv ${DUT}.netlist.v

${XILINX_LIB_DIR}/.git:
	git clone ${XILINX_LIB_URL}

clean:
	rm -f ${DUT}.sim sim.log sim.vcd
	rm -f ${DUT}.netlist.v synth.log
	rm -f ${DUT}.netlist.sim netlist_sim.log netlist_sim.vcd
