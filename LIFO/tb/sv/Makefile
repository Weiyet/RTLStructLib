
DUT ?= ../../src/lifo.v

sim: lifo_sim 
	./$< +VCDFILE=sim.vcd +VCDLEVEL=0 | tee sim.log

lifo_sim: tb.sv ${DUT}  # to generate executable file by using iverilator  
	iverilog -g2012 -s tb -o $@ $^

clean:
	rm -f lifo_sim sim.log sim.vcd
