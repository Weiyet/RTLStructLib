# Doubly Linked List

A synthesizable, single-clock hardware linked list with a fixed node pool and
next and previous pointers. Operations run through a bounded FSM; external ports,
operation codes and deterministic lowest-free-address allocation follow the
original module interface.

## Parameters and Integration

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `DATA_WIDTH` | 8 | Positive unsigned node-data width |
| `MAX_NODE` | 8 | Positive pool capacity, including 1 and non-power-of-two values |

`ADDR_WIDTH = ceil(log2(MAX_NODE+1))`. Valid node addresses are
`0..MAX_NODE-1`; `NULL = MAX_NODE`. Length uses the same width and can
represent a full pool. Include `src/rtl_list.f`; the RTL has no external
module dependency.

| Port | Direction | Meaning |
|------|-----------|---------|
| `clk`, `rst` | Input | Rising-edge clock; asynchronous active-high reset |
| `op[2:0]`, `op_start` | Input | Operation code and one-clock request |
| `data_in`, `addr_in` | Input | Insert/search value and physical address or logical index |
| `op_done`, `fault` | Output | One-clock completion and its error status |
| `data_out` | Output | Data from the last successful read |
| `pre_node_addr` | Output | Previous occupied node's address; NULL at head |
| `next_node_addr` | Output | Next occupied node's address; NULL at tail |
| `length`, `head`, `tail` | Output | Occupied count and endpoint addresses |
| `full`, `empty` | Output | Pool status |

## Operations and Handshake

| Code | Operation |
|------|-----------|
| 0 | Read an occupied physical address |
| 1 | Insert before an occupied address; addresses at/above NULL append |
| 2 | Delete the first matching value from head |
| 3 | Delete an occupied physical address |
| 5 | Insert before an index; indices at/above length append |
| 7 | Delete a valid zero-based index |

Codes 4/6, absent values, invalid read/delete targets, vacant address-insertion
targets and full insertions fault without changing the list.
For an empty list, use index insertion or a NULL address append.

Pulse `op_start` with stable command inputs, then wait for `op_done`.
Inputs are latched; requests during execution/completion are ignored.
Allow completion to clear before issuing another request. Holding the original
request until completion is also supported. Read outputs hold across
non-read operations and failed reads.

Reset clears data, validity, length and pending work; endpoint and pointer
outputs become NULL. An empty list has `head = tail = NULL`; a singleton's
neighbour pointer(s) are NULL. Reset asserts `empty` and clears `full`.
Links, length and endpoints update atomically with completion.

## Hardware Architecture and Verification

DLL stores both links. Address updates use the stored neighbours directly.
Indexed operations walk from the nearer endpoint, while value deletion
walks forward to preserve first-match semantics.
Storage uses resettable register arrays; the tested synthesis flow maps them
to flip-flops and multiplexers.

```bash
make -C Doubly_Linked_List/tb/sv sim SEED=123
make -C Doubly_Linked_List/tb/cocotb SEED=123
make -C Doubly_Linked_List/tb/sv netlist_sim SEED=123
python3 Utils/tb/linked_list/regress_rtl.py --module doubly
```

Use Linux/WSL with Make, Bash, Icarus Verilog, Python, cocotb and Yosys.
Standalone wrappers reuse the independent models in
[`Utils/tb/linked_list/`](../Utils/tb/linked_list/README.md), which documents
cycle bounds, parameter overrides, mapped-netlist simulation, regression
coverage and recorded results. VIP suites are separate from this runner.

Validated on 2026-10-15: all ten default cocotb scenarios and 2,817 SV
transactions pass, including the same transactions on the mapped netlist.
The shared regression records 31 real-RTL runs, four synthesis configurations
and three mapped-netlist configurations for this module.

