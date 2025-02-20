# Singly Linked List

A configurable hardware implementation of a singly linked list data structure in Verilog. The module supports basic linked list operations including insertion, deletion, and reading at specific addresses or indices, with full hardware synchronization and status monitoring.

## Features

- Configurable data width and maximum node count
- Multiple insertion and deletion operations
- Hardware-based node management
- Status monitoring (full, empty, length)
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
| next_node_addr  | Output    | ADDR_WIDTH   | Address of next node in list                 |
| length          | Output    | ADDR_WIDTH   | Current number of nodes in list              |
| head            | Output    | ADDR_WIDTH   | Address of first node                        |
| tail            | Output    | ADDR_WIDTH   | Address of last node                         |
| full            | Output    | 1            | List full indicator                          |
| empty           | Output    | 1            | List empty indicator                         |
| fault           | Output    | 1            | Error indicator                              |

## Supported Operations

| Op Code | Operation           | Description                                             |
|---------|--------------------|---------------------------------------------------------|
| 0       | Read_Addr          | Read data at specified address                          |
| 1       | Insert_At_Addr     | Insert new node at specified address                    |
| 2       | Delete_Value       | Delete first occurrence of specified value              |
| 3       | Delete_At_Addr     | Delete node at specified address                        |
| 5       | Insert_At_Index    | Insert new node at specified index                      |
| 7       | Delete_At_Index    | Delete node at specified index                          |

## State Machine

The module implements a state machine with the following states:

1. **IDLE (3'b000)**
   - Waits for operation start
   - Validates operation parameters
   - Initializes operation sequence

2. **FIND_ADDR (3'b001)**
   - Traverses list to find target address
   - Used for address-based operations

3. **FIND_VALUE (3'b010)**
   - Traverses list to find target value
   - Used for value-based deletion

4. **INSERT_STG1 (3'b011)**
   - First stage of node insertion
   - Updates node links

5. **EXECUTE (3'b100)**
   - Completes operation
   - Updates status signals

6. **FAULT (3'b101)**
   - Handles error conditions

## Usage Example

```verilog
// Instantiate a linked list with 16 nodes and 32-bit data
singly_linked_list #(
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
    .next_node_addr(next_addr),
    .length(list_length),
    .head(head_addr),
    .tail(tail_addr),
    .full(list_full),
    .empty(list_empty),
    .fault(error_signal)
);
```

## Operation Protocol

1. Set `data_in` and/or `addr_in` as required by operation
2. Set `op` to desired operation code
3. Assert `op_start` for one clock cycle
4. Wait for `op_done` assertion
5. Check `fault` signal for operation status
6. Read `data_out` if applicable

## Reset Behavior

On assertion of reset:
- All nodes are invalidated
- Head and tail pointers set to NULL
- Length cleared to zero
- All node data cleared
- All status signals deasserted

## Implementation Notes

1. **Memory Organization**:
   - Next node pointers stored separately
   - Valid bits for node tracking

2. **Address Handling**:
   - NULL address = MAX_NODE
   - Valid addresses: 0 to (MAX_NODE-1)

3. **Error Conditions**:
   - List full during insertion
   - List empty during deletion/read
   - Invalid address/index
   - Address overflow

## Limitations

- Fixed maximum size defined by MAX_NODE
- Sequential search for operations
- Single operation at a time
- No concurrent access support
- User could actually use distributed RAM to stored data if necessary 
