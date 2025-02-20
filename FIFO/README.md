# FIFO (Queue)

A configurable FIFO (First-In-First-Out) buffer implementation in Verilog with support for both synchronous and asynchronous clock domains. The module uses Gray code for pointer synchronization in asynchronous mode to prevent metastability issues.

## Features

- Configurable data width and depth
- Support for both synchronous and asynchronous clock domains
- Optional registered read output
- Gray code synchronization for clock domain crossing
- Full and empty status flags
- Automatic pointer wraparound
- Parameterized design for easy customization

## Parameters

| Parameter    | Description                                      | Default |
|-------------|--------------------------------------------------|---------|
| DEPTH       | Number of entries in the FIFO                     | 12      |
| DATA_WIDTH  | Width of each data entry                         | 8       |
| ASYNC       | Enable asynchronous mode (1) or synchronous (0)   | 1       |
| RD_BUFFER   | Enable registered read output (1) or bypass (0)   | 1       |

## Interface Signals

| Signal      | Direction | Width         | Description                                    |
|-------------|-----------|---------------|------------------------------------------------|
| rd_clk      | Input     | 1            | Read clock domain                              |
| wr_clk      | Input     | 1            | Write clock domain                             |
| rst         | Input     | 1            | Active high reset                              |
| data_wr     | Input     | DATA_WIDTH   | Data input for writing                        |
| wr_en       | Input     | 1            | Write enable signal                           |
| fifo_full   | Output    | 1            | FIFO full indicator                           |
| data_rd     | Output    | DATA_WIDTH   | Data output from reading                      |
| rd_en       | Input     | 1            | Read enable signal                            |
| fifo_empty  | Output    | 1            | FIFO empty indicator                          |

## Usage Example

```verilog
// Instantiate a 16-deep, 32-bit wide asynchronous FIFO with registered output
fifo #(
    .DEPTH(16),
    .DATA_WIDTH(32),
    .ASYNC(1),
    .RD_BUFFER(1)
) fifo_inst (
    .rd_clk(read_clock),
    .wr_clk(write_clock),
    .rst(reset),
    .data_wr(write_data),
    .wr_en(write_enable),
    .fifo_full(full_flag),
    .data_rd(read_data),
    .rd_en(read_enable),
    .fifo_empty(empty_flag)
);
```

## Design Notes

1. **Clock Domain Crossing**: In asynchronous mode (ASYNC=1), the design uses Gray code encoding for pointer synchronization to prevent metastability issues when crossing clock domains.

2. **Read Buffer**: When RD_BUFFER=1, the read data output is registered, adding one clock cycle of latency but improving timing. When RD_BUFFER=0, the read data is combinatorial.

3. **Full/Empty Flags**: 
   - The empty flag is asserted when read and write pointers are equal
   - The full flag is asserted when the next write pointer would equal the current read pointer

4. **Reset Behavior**: 
   - All pointers are reset to zero
   - All memory locations are cleared
   - All flags are deasserted

## Implementation Details

The module uses separate read and write pointers for tracking FIFO occupancy. In asynchronous mode, these pointers are converted to Gray code before being synchronized across clock domains. The implementation includes:

- Binary counters for read/write operation
- Gray code conversion for pointer synchronization
- Two-stage synchronizers for clock domain crossing
- Configurable output registration
- Automatic pointer wraparound at FIFO boundaries

## Timing Considerations

1. In asynchronous mode, allow at least 2 clock cycles for pointer synchronization
2. When RD_BUFFER=1, read data is available one clock cycle after rd_en assertion
3. Full and empty flags are registered outputs

## Limitations

- The DEPTH parameter must be a power of 2 for proper wraparound behavior
- Simultaneous read/write at full/empty conditions should be managed by external logic
- The reset signal must be synchronized to both clock domains
