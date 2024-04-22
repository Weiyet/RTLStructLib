
DUT ?= ../../src/fifo.v

sim: fifo_sim 
	./$< +VCDFILE=sim.vcd +VCDLEVEL=0 | tee sim.log

fifo_sim: tb.sv ${DUT}  # to generate executable file by using iverilator  
	iverilog -g2012 -s tb -o $@ $^

clean:
	rm -f fifo_sim sim.log sim.vcd
