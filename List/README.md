# List Module 

## Overview
The List module is a versatile data storage and manipulation component implemented in Verilog. It provides various operations for managing and processing data, including reading, writing, summing, and sorting functionalities. This module can be particularly useful in FPGA designs requiring data buffering, accumulation, or processing.

## Features
- Data storage with configurable width and length
- Multiple data manipulation operations:
  - Read/write operations
  - Element searching
  - Data summation with multiple implementation methods
  - Sorting (ascending and descending)
- Configurable sum calculation methods:
  - Parallel sum (combinatorial)
  - Sequential sum
  - Adder tree
    
## Module Instantiation
``` verilog
// Instantiation with custom parameters
list #(
    .DATA_WIDTH(16),         // 16-bit data elements
    .LENGTH(32),             // List can store up to 32 elements
    .SUM_METHOD(1)           // Use sequential summation method
) custom_list (
    .clk(clk),
    .rst(rst),
    .op_sel(op_sel),
    .op_en(op_en),
    .data_in(data_in),
    .index_in(index_in),
    .data_out(data_out),
    .op_done(op_done),
    .op_in_progress(op_in_progress),
    .op_error(op_error)
);
```

## Parameters

| Parameter    | Description                                      | Default |
|--------------|--------------------------------------------------|---------|
| DATA_WIDTH   | Width of each data element in bits               | 32      |
| LENGTH       | Maximum number of elements in the list           | 8       |
| SUM_METHOD   | Method for calculating sum (0: parallel, 1: sequential, 2: adder tree) | 0 |

## IO Ports

| Port           | Direction | Width                         | Description                               |
|----------------|-----------|-------------------------------|-------------------------------------------|
| clk            | input     | 1                             | System clock                              |
| rst            | input     | 1                             | Reset signal (active high)                |
| op_sel         | input     | 2                             | Operation selector                        |
| op_en          | input     | 1                             | Operation enable                          |
| data_in        | input     | DATA_WIDTH                    | Input data for write operations           |
| index_in       | input     | LENGTH_WIDTH                  | Index for read/write operations           |
| data_out       | output    | LENGTH_WIDTH+DATA_WIDTH       | Output data                               |
| op_done        | output    | 1                             | Operation completion indicator            |
| op_in_progress | output    | 1                             | Operation is in progress                  |
| op_error       | output    | 1                             | Operation error indicator                 |

## Operation Codes

| op_sel | Operation           | Description                              |
|--------|---------------------|------------------------------------------|
| 3'b000 | Read                | Read data from specified index           |
| 3'b001 | Write               | Write data to specified index            |
| 3'b010 | Find All Indices    | Find all indices matching data_in        |
| 3'b011 | Find First Index    | Find first index matching data_in        |
| 3'b100 | Sum                 | Calculate sum of all elements            |
| 3'b101 | Sort Ascending      | Sort elements in ascending order         |
| 3'b110 | Sort Descending     | Sort elements in descending order        |

## State Machine
The module implements a simple state machine with the following states:
- **IDLE**: Default state, waiting for operation
- **SUM**: Calculating sum in progress (for sequential or adder tree methods)
- **SORT**: Sorting the list in progress (implementation in progress)
- **ACCESS_DONE**: Operation completed, transitioning back to IDLE

## Implementation Notes
- The internal storage is implemented as a register array, which could be replaced with RAM for larger data sizes
- The parallel sum implementation uses combinatorial logic
- Sequential sum and adder tree implementations are placeholders in the current version
