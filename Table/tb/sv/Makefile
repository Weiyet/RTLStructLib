
DUT ?= table_top
SIM_OPTS ?= ../../src/table.sv
SEED ?= $$(shuf -i 1-10000 -n 1)

# DUT parameter #"-p" iverilog command flags
COMPILE_ARGS = -P tb.TABLE_SIZE=32
COMPILE_ARGS += -P tb.DATA_WIDTH=8
COMPILE_ARGS += -P tb.INPUT_RATE=2
COMPILE_ARGS += -P tb.OUTPUT_RATE=2
COMPILE_ARGS += -P tb.TB_CLK_PERIOD=100
COMPILE_ARGS += -P tb.TB_TEST_WEIGHT=1 
COMPILE_ARGS += -P tb.TB_SIM_TIMEOUT=30 #//ms.

XILINX_LIB_URL ?= https://github.com/Xilinx/XilinxUnisimLibrary.git
XILINX_LIB_DIR ?= XilinxUnisimLibrary/verilog/src

sim: gen_sim 
	./${DUT}.sim +VCDFILE=sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee sim.log

gen_sim: tb.sv ${SIM_OPTS}  # to generate executable file by using iverilator  
	iverilog -g2012 -s tb ${COMPILE_ARGS} -o ${DUT}.sim $^

synth: ${SIM_OPTS}
	yosys -p synth_xilinx ${SIM_OPTS} -L synth.log -o ${DUT}.netlist.v
    #timeout

netlist_sim: gen_netlist_sim
	./${DUT}.netlist.sim +VCDFILE=netlist_sim.vcd +VCDLEVEL=0 +SEED=${SEED} | tee netlist_sim.log

gen_netlist_sim: tb.sv ${DUT}.netlist.v | ${XILINX_LIBS_DIR}/.git
	iverilog -g2012 -s tb -y ${XILINX_LIB_DIR} -y ${XILINX_LIB_DIR}/unisims -DXILINX_GLS ${COMPILE_ARGS} -o ${DUT}.netlist.sim $^

${XILINX_LIBS_DIR}/.git:
	git clone ${XILINX_LIB_URL}

clean:
	rm -f ${DUT}_sim sim.log sim.vcd
	rm -f ${DUT}.netlist.v synth.log
