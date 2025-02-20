# Doubly Linked List

A configurable hardware implementation of a doubly linked list data structure in Verilog. The module supports bidirectional traversal with both forward and backward pointers, providing efficient insertion, deletion, and reading operations at specific addresses or indices.

## Features

- Configurable data width and maximum node count
- Bidirectional traversal support
- Multiple insertion and deletion operations
- Hardware-based node management
- Full status monitoring (full, empty, length)
- Fault detection
- Head and tail pointer tracking
- Synchronous operation with start/done handshaking

## Parameters

| Parameter    | Description                                      | Default |
|-------------|--------------------------------------------------|---------|
| DATA_WIDTH  | Width of data stored in each node                | 8       |
| MAX_NODE    | Maximum number of nodes supported                | 8       |

## Interface Signals

| Signal           | Direction | Width         | Description                                    |
|-----------------|-----------|---------------|------------------------------------------------|
| clk             | Input     | 1            | System clock                                   |
| rst             | Input     | 1            | Active high reset                              |
| data_in         | Input     | DATA_WIDTH   | Input data for insertion                      |
| addr_in         | Input     | ADDR_WIDTH   | Target address/index for operations           |
| op              | Input     | 3            | Operation code                                |
| op_start        | Input     | 1            | Start signal for operation                    |
| op_done         | Output    | 1            | Operation completion signal                   |
| data_out        | Output    | DATA_WIDTH   | Output data from read operations             |
| pre_node_addr   | Output    | ADDR_WIDTH   | Address of previous node in list             |
| next_node_addr  | Output    | ADDR_WIDTH   | Address of next node in list                 |
| length          | Output    | ADDR_WIDTH   | Current number of nodes in list              |
| head            | Output    | ADDR_WIDTH   | Address of first node                        |
| tail            | Output    | ADDR_WIDTH   | Address of last node                         |
| full            | Output    | 1            | List full indicator                          |
| empty           | Output    | 1            | List empty indicator                         |
| fault           | Output    | 1            | Error indicator                              |

## Supported Operations

| Op Code | Operation         | Description                                             |
|---------|------------------|---------------------------------------------------------|
| 0       | Read_Addr        | Read data at specified address                          |
| 1       | Insert_Addr      | Insert new node at specified address                    |
| 2       | Delete_Value     | Delete first occurrence of specified value              |
| 3       | Delete_Addr      | Delete node at specified address                        |
| 5       | Insert_Index     | Insert new node at specified index                      |
| 7       | Delete_Index     | Delete node at specified index                          |

## State Machine

The module implements a FSM with the following states:

1. **IDLE (3'b000)**
   - Initial state, waits for operation start
   - Validates operation parameters
   - Handles direct head/tail operations

2. **FIND_ADDR (3'b001)**
   - Traverses list to find target address
   - Used for address-based operations

3. **FIND_VALUE (3'b010)**
   - Traverses list to find target value
   - Used for value-based deletion

4. **FIND_INDEX (3'b110)**
   - Traverses list to find target index
   - Supports both ascending and descending search

5. **INSERT_STG1 (3'b011)**
   - First stage of node insertion
   - Updates bidirectional links

6. **EXECUTE (3'b100)**
   - Completes operation
   - Updates status signals

7. **FAULT (3'b101)**
   - Handles error conditions

## Memory Organization

The implementation uses three separate memory arrays:
1. Data storage (`node_data`)
2. Forward pointers (`node_next_node_addr`)
3. Backward pointers (`node_pre_node_addr`)

This organization allows for:
- Independent access to data and pointers
- Efficient pointer updates
- Parallel validity checking

## Usage Example

```verilog
// Instantiate a doubly linked list with 16 nodes and 32-bit data
doubly_linked_list #(
    .DATA_WIDTH(32),
    .MAX_NODE(16)
) list_inst (
    .clk(system_clock),
    .rst(reset),
    .data_in(input_data),
    .addr_in(target_addr),
    .op(operation_code),
    .op_start(start_signal),
    .op_done(done_signal),
    .data_out(output_data),
    .pre_node_addr(prev_addr),
    .next_node_addr(next_addr),
    .length(list_length),
    .head(head_addr),
    .tail(tail_addr),
    .full(list_full),
    .empty(list_empty),
    .fault(error_signal)
);

