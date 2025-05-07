# Hash Table Module
## Overview
This Verilog module implements a flexible hash table with configurable collision resolution methods and hash algorithms. It provides support for key-value storage with operations such as insert, delete, and search.

## Features
- Configurable key and value widths
- Support for different collision resolution methods
- Multiple hash algorithm options
- Synchronous operation with reset capability
- Collision tracking and error reporting

## Parameters
| Parameter | Description | Default |
|-----------|-------------|---------|
| KEY_WIDTH | Width of keys in bits | 32 |
| VALUE_WIDTH | Width of values in bits | 32 |
| TOTAL_ENTRY | Number of indices in the hash table | 64 |
| CHAINING_SIZE | Maximum chain length for collision resolution | 4 |
| COLLISION_METHOD | Method for handling collisions | "MULTI_STAGE_CHAINING" |
| HASH_ALGORITHM | Algorithm used for hashing | "MODULUS" |

## Port Descriptions
### Input Ports
| Port | Width | Description |
|------|-------|-------------|
| clk | 1 | System clock signal |
| rst | 1 | Active-high reset signal |
| key_in | KEY_WIDTH | Key for insert, delete, or search operations |
| value_in | VALUE_WIDTH | Value to be stored (for insert operations) |
| op_sel | 2 | Operation selector (00: Insert, 01: Delete, 10: Search) |
| op_en | 1 | Operation enable signal |

### Output Ports
| Port | Width | Description |
|------|-------|-------------|
| value_out | VALUE_WIDTH | Value retrieved during search operations |
| op_done | 1 | Operation completion indicator |
| op_error | 1 | Error indicator (FULL for insert, KEY_NOT_FOUND for delete/search) |
| collision_count | log2(CHAINING_SIZE) | Number of collisions encountered |

## Collision Methods
- **MULTI_STAGE_CHAINING**: Multiple entries at the same index using a linked list approach
- **LINEAR_PROBING**: Referenced in parameters but not fully implemented in the provided code

## Hash Algorithms
- **MODULUS**: Simple modulus operation (key % TABLE_SIZE)
- **SHA1**, **FNV1A**: Referenced in parameters but not fully implemented in the provided code

## Timing
- All operations are synchronized to the positive edge of the clock
- Reset is asynchronous and active-high
- Operations are initiated when op_en is asserted
- op_done indicates completion of an operation

## Usage Example
```verilog
hash_table #(
    .KEY_WIDTH(32),
    .VALUE_WIDTH(32),
    .TOTAL_ENTRY(128),
    .CHAINING_SIZE(8),
    .COLLISION_METHOD("MULTI_STAGE_CHAINING"),
    .HASH_ALGORITHM("MODULUS")
) hash_module (
    .clk(system_clk),
    .rst(system_rst),
    .key_in(key),
    .value_in(value),
    .op_sel(operation),
    .op_en(enable),
    .value_out(retrieved_value),
    .op_done(operation_complete),
    .op_error(operation_error),
    .collision_count(collisions)
);
```

## Implementation Details
- Uses a state machine for operation control
- Implements chained hash entries for collision resolution
- Provides error reporting for table overflow or key not found conditions
- Uses Verilog parameter-based configuration for flexibility

## Limitations and Issues
- Implementation for alternative hash algorithms is mentioned but not provided

## Performance Considerations
- Search and delete operations may require multiple cycles depending on chain length
- Performance degrades as collision chains grow longer
- No optimization for locality or cache behavior
- Please consider using [CAM(Content Addressable Memory)](https://en.wikipedia.org/wiki/Content-addressable_memory) if you have the resources.
