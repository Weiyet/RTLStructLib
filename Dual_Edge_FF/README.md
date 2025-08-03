# Dual Edge Flip Flop
## Overview
This Verilog module implements a dual-edge triggered flip-flop that can capture data on both the positive and negative edges of the clock signal. This design effectively doubles the data throughput rate compared to traditional single-edge flip-flops by utilizing both clock transitions for data latching operations.

## Parameters
| Parameter    | Description                           | Default |
|-------------|---------------------------------------|---------|
| DATA_WIDTH  | Width of data bus in bits             | 8       |
| RESET_VALUE | Reset value of flops                  | 0       |

## Port Descriptions
### Input Ports
| Port               | Width       | Description                                    |
|-------------------|-------------|------------------------------------------------|
| clk               | 1           | System clock signal                            |
| rst_n             | 1           | Active-low asynchronous reset signal           |
| data_in           | DATA_WIDTH  | Input data to be latched                       |
| pos_edge_latch_en | DATA_WIDTH  | Per-bit latch enable for positive clock edge  |
| neg_edge_latch_en | DATA_WIDTH  | Per-bit latch enable for negative clock edge  |

### Output Ports
| Port     | Width      | Description                    |
|----------|------------|--------------------------------|
| data_out | DATA_WIDTH | Latched output data           |


## Usage Example
Below shows a simple usage of a counter that increments on both edges of the clock.
```verilog
always @ (*) begin
  if (data_out <= {(DATA_WIDTH){1'b1}}) input_data <= data_out + 1;
  else input_data <= data_out;
end

dual_edge_ff #(
    .DATA_WIDTH(16),
    .RESET_VALUE(16'h0000)
) dual_ff_inst (
    .clk(system_clk),
    .rst_n(system_rst_n),
    .data_in(input_data),
    .pos_edge_latch_en(16'hFFFF),  // Enable all bits on positive edge
    .neg_edge_latch_en(16'hFFFF),  // Enable all bits on negative edge
    .data_out(output_data)
);
```
