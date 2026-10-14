# Circular Linked List

A register-backed, circular doubly linked list with the operation codes,
node allocation, and port names used by [Doubly Linked List](../Doubly_Linked_List/README.md)
and [Singly Linked List](../Singly_Linked_List/README.md). Index zero is the
designated head; occupied node addresses remain stable until deletion.

## Ring and Storage

For every nonempty list, `tail.next = head` and `head.prev = tail`.
A singleton's two links point to itself. An empty list has `head = tail = MAX_NODE`.
The separate data, next-pointer, previous-pointer, and validity arrays follow
the existing linked-list organization. Inserts allocate the lowest free address;
deletion releases that address for reuse. Updates to links, length, head, and
tail commit together at operation completion.

For example, append 11, append 22, then insert 33 at index 1:

| Index | Node address | Data | Previous | Next |
|-------|--------------|------|----------|------|
| 0 | 0 | 11 | 1 | 2 |
| 1 | 2 | 33 | 0 | 1 |
| 2 | 1 | 22 | 2 | 0 |

Following either link repeatedly traverses the same ring. Searches terminate
after at most `length` nodes rather than waiting for a NULL link.

## Parameters and Interface

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `DATA_WIDTH` | 8 | Positive unsigned data width |
| `MAX_NODE` | 8 | Positive capacity; includes single-node and non-power-of-two sizes |

`ADDR_WIDTH = ceil(log2(MAX_NODE+1))`. Physical addresses are `0..MAX_NODE-1`;
`MAX_NODE` is NULL, matching the existing RTL. Length uses the same width and
can represent a full pool. Include `src/rtl_list.f` in the consuming project.

| Port | Direction | Meaning |
|------|-----------|---------|
| `clk`, `rst` | Input | Rising-edge clock; asynchronous active-high reset |
| `op[2:0]`, `op_start` | Input | Operation code and request enable |
| `addr_in` | Input | Physical address or logical index, according to the operation |
| `data_in` | Input | Inserted value or deletion search key |
| `op_done`, `fault` | Output | One-cycle completion and its error status |
| `busy` | Output | Command accepted and still executing |
| `data_out` | Output | Data returned by a successful address read |
| `pre_node_addr`, `next_node_addr` | Output | Both neighbours returned by a successful read |
| `length`, `head`, `tail` | Output | Occupied count and designated endpoints |
| `full`, `empty` | Output | Capacity and emptiness status |

`busy` is an additional port; the remaining interface follows Doubly Linked List.
Reset invalidates all nodes and aborts a pending request. Read data resets to
zero and pointer outputs reset to NULL. Reset asserts `empty` and clears `full`.

## Operations

| Code | Operation | Behavior |
|------|-----------|----------|
| 0 | Read address | Return an occupied node's data and its two circular links |
| 1 | Insert address | Insert before an occupied address; addresses at/above NULL append |
| 2 | Delete value | Delete the first matching node when traversing forward from head |
| 3 | Delete address | Remove the occupied node at that physical address |
| 5 | Insert index | Insert before the zero-based index; indices at/above length append |
| 7 | Delete index | Delete the node at the zero-based index |

Codes 4 and 6 fault. Reads/deletions at unused or out-of-range addresses,
invalid deletion indices, missing values, and insertion into a full pool fault
without changing the ring. An unused physical address is not an insertion
target: use index insertion or the NULL append sentinel to allocate a node.
For an empty list, append by address or insert at any index creates a singleton.

## Request Timing

Present `op`, `addr_in`, and `data_in` before a rising edge with `op_start=1`,
when both `busy` and `op_done` are low. One request clock is sufficient;
the command inputs are latched. Further requests during execution or the
completion cycle are ignored. Wait for `op_done`, sample `fault` and read
outputs, and allow completion to clear before issuing another request.

`busy` falls when `op_done` rises; `fault` is asserted only with completion.
Non-read operations and failed reads return zero data and NULL pointer outputs.
Address access takes constant time; index access and value searches take
linear time. Repeated reads using returned neighbours support traversal across
the head/tail boundary without changing the designated endpoints.

## Build and Verification

Use Linux/WSL with Make, Bash, Icarus Verilog, Python, cocotb, and Yosys:

```bash
make -C Circular_Linked_List/tb/sv sim SEED=123
make -C Circular_Linked_List/tb/cocotb SEED=123
python3 Circular_Linked_List/tb/support/regress_rtl.py
make -C Circular_Linked_List/tb/sv synth MAX_NODE=5 DATA_WIDTH=17
```

Both benches accept `MAX_NODE`, `DATA_WIDTH`, `SEED`, `WAVES=1`, and
`TB_TIMEOUT_CYCLES`. Clean before changing parameters in a reused build directory.
SV's `TEST` selector accepts `all`, `empty`, `singleton`, `insert`, `delete`,
`reuse`, `traversal`, `random`, and `reset`. Use the default cocotb `check`
target to enforce failure status through the repository's XML result checker.
Build products and waveforms remain under ignored `sim_build/` directories.

Both benches use independent ordered address/value models. They check every
occupied and unused address, both neighbours, all status outputs, three full
laps in each direction, duplicates, address reuse, ignored busy requests,
input latching, reset during search, and 200 random operations per run.

Validated on 2026-10-14 with Icarus Verilog 11.0, cocotb 1.8.1, and Yosys 0.9:

- Default 8-node / 8-bit RTL: all 8 cocotb scenarios and 2,807 SV transactions pass
  with `SEED=123`.
- All 31 real-RTL runs pass: eight capacity/width combinations in both benches,
  SV seeds 0, 1, and 19, cocotb seeds 0 through 9, and waveform checks.
- Both Makefiles reject deliberately forced operation timeouts.
- Xilinx synthesis, structural checks, and no-latch assertions pass at
  8 nodes / 8 bits, 1 node / 1 bit, 5 nodes / 17 bits, and 33 nodes / 8 bits.

The regression runs two simulators concurrently and allows 180 host seconds
per run (`RTL_RUN_TIMEOUT` overrides this). The independent per-operation
simulation-cycle bound remains enforced. Memories map to registers in this
synthesis flow; gate-level simulation and routed timing are not measured.
