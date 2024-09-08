
DUT = lifo
SIM_OPTS ?= ../../src/lifo.sv
SEED ?= $$(shuf -i 1-10000 -n 1)
XILINX_LIB_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_LIB_DIR ?= XilinxUnisimLibrary/verilog/src

sim: gen_sim 
	./${DUT}.sim +VCDFILE=sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee sim.log

gen_sim: tb.sv ${SIM_OPTS}  # to generate executable file by using iverilator  
	iverilog -g2012 -s tb -o ${DUT}.sim $^

synth: ${SIM_OPTS}
	yosys -p synth_xilinx ${SIM_OPTS} -L synth.log -o ${DUT}.netlist.v
    #timeout

netlist_sim: gen_netlist_sim
	./${DUT}.netlist.sim +VCDFILE=netlist_sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee netlist_sim.log

gen_netlist_sim: tb.sv ${DUT}.netlist.v | ${XILINX_LIBS_DIR}
	iverilog -g2012 -s tb -y ${XILINX_LIB_DIR} -y ${XILINX_LIB_DIR}/unisims -DXILINX_GLS -o ${DUT}.netlist.sim $^

${XILINX_LIBS_DIR}:
	git clone ${XILINX_LIB_URL}

clean:
	rm -f ${DUT}_sim sim.log sim.vcd
	rm -f ${DUT}.netlist.v synth.log
