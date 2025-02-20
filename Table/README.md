# Multi-port table

## Overview
This Verilog module implements a flexible table structure that supports multiple simultaneous read and write operations. It functions similarly to a register file, providing direct indexed access to stored data without the need for hashing mechanisms.

## Features
- Configurable table size and data width
- Support for multiple simultaneous write operations
- Support for multiple simultaneous read operations
- Synchronous operation with reset capability
- Direct indexed access to stored data

## Parameters

| Parameter    | Description                                    | Default |
|-------------|------------------------------------------------|---------|
| TABLE_SIZE  | Number of entries in the table                 | 32      |
| DATA_WIDTH  | Width of each data entry in bits               | 8       |
| INPUT_RATE  | Number of simultaneous write operations        | 2       |
| OUTPUT_RATE | Number of simultaneous read operations         | 2       |

## Port Descriptions

### Input Ports

| Port      | Width                           | Description                    |
|-----------|----------------------------------|--------------------------------|
| clk       | 1                                | System clock signal            |
| rst       | 1                                | Active-high reset signal       |
| wr_en     | INPUT_RATE                       | Write enable signals           |
| rd_en     | 1                                | Read enable signal             |
| index_wr  | INPUT_RATE * log2(TABLE_SIZE)    | Write address indices         |
| index_rd  | OUTPUT_RATE * log2(TABLE_SIZE)   | Read address indices          |
| data_wr   | INPUT_RATE * DATA_WIDTH          | Write data input              |

### Output Ports

| Port      | Width                    | Description          |
|-----------|--------------------------|----------------------|
| data_rd   | OUTPUT_RATE * DATA_WIDTH | Read data output    |

## Timing
- All operations are synchronized to the positive edge of the clock
- Reset is asynchronous and active-high
- Write operations occur on the next clock edge after wr_en is asserted
- Read operations occur on the next clock edge after rd_en is asserted

## Usage Example
```verilog
table_top #(
    .TABLE_SIZE(64),
    .DATA_WIDTH(16),
    .INPUT_RATE(2),
    .OUTPUT_RATE(2)
) table_inst (
    .clk(system_clk),
    .rst(system_rst),
    .wr_en(write_enable),
    .rd_en(read_enable),
    .index_wr(write_indices),
    .index_rd(read_indices),
    .data_wr(write_data),
    .data_rd(read_data)
);
```

## Implementation Details
- Uses a 2D register array for data storage
- Implements parallel write operations using generate blocks
- Supports concurrent read operations
- Reset initializes all storage elements to zero
- Uses Verilog-2001 syntax and features

## Performance Considerations
- All read and write operations complete in a single clock cycle
- No read-after-write hazard protection is implemented
- Care should be taken when accessing the same index simultaneously

## Limitations
- No built-in error checking for invalid indices
- No protection against simultaneous read/write to same location
- Write operations take precedence in case of conflicts

## Author
Wei Yet Ng  
[LinkedIn Profile](https://www.linkedin.com/in/wei-yet-ng-065485119/)

## Version History
- Created: January 31, 2025
- Last Updated: February 09, 2024

## License
[Specify license information here]
