# LIFO (Stack) 

A configurable LIFO (Last-In-First-Out) buffer implementation in Verilog. This module implements a stack-like behavior where the last element written is the first one to be read out. The design includes bypass functionality for simultaneous read/write operations.

## Features

- Configurable data width and depth
- Single clock domain operation
- Full and empty status flags
- Bypass path for simultaneous read/write
- Registered read output
- Automatic pointer management
- Parameterized design for easy customization

## Parameters

| Parameter    | Description                                      | Default |
|-------------|--------------------------------------------------|---------|
| DEPTH       | Number of entries in the LIFO                     | 12      |
| DATA_WIDTH  | Width of each data entry                         | 8       |

## Interface Signals

| Signal      | Direction | Width         | Description                                    |
|-------------|-----------|---------------|------------------------------------------------|
| clk         | Input     | 1            | System clock                                   |
| rst         | Input     | 1            | Active high reset                              |
| data_wr     | Input     | DATA_WIDTH   | Data input for writing                        |
| wr_en       | Input     | 1            | Write enable signal                           |
| lifo_full   | Output    | 1            | LIFO full indicator                           |
| data_rd     | Output    | DATA_WIDTH   | Data output from reading                      |
| rd_en       | Input     | 1            | Read enable signal                            |
| lifo_empty  | Output    | 1            | LIFO empty indicator                          |

## Usage Example

```verilog
// Instantiate a 16-deep, 32-bit wide LIFO
lifo #(
    .DEPTH(16),
    .DATA_WIDTH(32)
) lifo_inst (
    .clk(system_clock),
    .rst(reset),
    .data_wr(write_data),
    .wr_en(write_enable),
    .lifo_full(full_flag),
    .data_rd(read_data),
    .rd_en(read_enable),
    .lifo_empty(empty_flag)
);
```

## Operation Modes

The module supports three operation modes:

1. **Write Operation (wr_op)**
   - Activated when wr_en=1 and rd_en=0
   - Data is written to current pointer location
   - Pointer increments if not full

2. **Read Operation (rd_op)**
   - Activated when rd_en=1 and wr_en=0
   - Data is read from (pointer-1) location
   - Pointer decrements if not empty

3. **Bypass Operation (bypass_op)**
   - Activated when both wr_en=1 and rd_en=1
   - Input data (data_wr) is directly passed to output (data_rd)
   - Pointer remains unchanged

## Design Notes

1. **Pointer Management**:
   - Single pointer tracks both read and write positions
   - Increments on write, decrements on read
   - Range: 0 to (DEPTH-1)

2. **Memory Organization**:
   - Stack-like structure with DEPTH entries
   - Each entry is DATA_WIDTH bits wide
   - Last written data is first to be read

3. **Flag Generation**:
   - Empty flag is combinatorial (pointer = 0)
   - Full flag is registered (pointer = DEPTH-1)
   - Flags prevent invalid operations

## Reset Behavior

On assertion of reset:
- Pointer is cleared to zero
- All memory locations are cleared
- Full flag is deasserted
- Output data is cleared
- Empty flag becomes active

## Timing Considerations

1. All outputs except lifo_empty are registered
2. Data is available on the next clock cycle after rd_en assertion
3. Bypass operation provides data in the same clock cycle

## Limitations

- Single clock domain operation only
- No protection against overflow/underflow if flags are ignored
- DEPTH parameter should be at least 2 for proper operation
- Simultaneous read/write operations bypass the stack memory

## Alternative Implementation Note

The commented code at the bottom of the module suggests an alternative implementation for full flag handling and read operations, which could be implemented if different timing behavior is needed.
