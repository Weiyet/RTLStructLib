# Doubly Linked List UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── dll_vip_pkg.sv                        [Main package + enums]
│   ├── dll_vip_config.sv                     [Configuration class]
│   └── dll_vip_seq_item.sv                   [Transaction definitions]
├── interface/                                 [Interface definition]
│   └── dll_vip_if.sv                         [Virtual interface]
├── agent/                                     [Agent layer components]
│   ├── dll_vip_driver.sv                     [Driver implementation]
│   ├── dll_vip_monitor.sv                    [Monitor implementation]
│   ├── dll_vip_sequencer.sv                  [Sequencer]
│   └── dll_vip_agent.sv                      [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── dll_vip_env.sv                        [Environment]
│   └── dll_vip_scoreboard.sv                 [Checking with doubly linked list model]
├── sequences/                                 [Test sequences]
│   ├── dll_vip_base_seq.sv                   [Base sequence]
│   ├── dll_vip_insert_seq.sv                 [Insert sequences (addr & index)]
│   ├── dll_vip_read_seq.sv                   [Read sequence]
│   └── dll_vip_delete_seq.sv                 [Delete sequences (addr, index, value)]
└── sim/                                       [Testbench]
    ├── tb_top.sv                              [Testbench top module]
    └── tests/
        ├── dll_vip_base_test.sv               [Base test class]
        └── dll_vip_simple_test.sv             [Simple & random tests]
```

## 🚀 Quick Start

**Step 1:** Update interface signals in your testbench:
```systemverilog
dll_vip_if dut_if(clk);
// Connect to DUT
uvm_config_db#(virtual dll_vip_if)::set(null, "*", "dll_vip_vif", dut_if);
```

**Step 2:** Configure DUT parameters in your test:
```systemverilog
cfg = dll_vip_config::type_id::create("cfg");
cfg.DATA_WIDTH = 8;
cfg.MAX_NODE = 8;
uvm_config_db#(dll_vip_config)::set(this, "*", "dll_vip_cfg", cfg);
```

**Step 3:** Create environment:
```systemverilog
dll_env = dll_vip_env::type_id::create("dll_env", this);
```

## 🚀 Available Sequences

**Insert at Address:**
```systemverilog
dll_vip_insert_at_addr_seq insert_seq = dll_vip_insert_at_addr_seq::type_id::create("insert_seq");
insert_seq.num_inserts = 5;
insert_seq.start(env.get_sequencer());
```

**Insert at Index:**
```systemverilog
dll_vip_insert_at_index_seq insert_seq = dll_vip_insert_at_index_seq::type_id::create("insert_seq");
insert_seq.num_inserts = 5;
insert_seq.start(env.get_sequencer());
```

**Read from Address:**
```systemverilog
dll_vip_read_seq read_seq = dll_vip_read_seq::type_id::create("read_seq");
read_seq.num_reads = 5;
read_seq.start(env.get_sequencer());
```

**Delete at Address:**
```systemverilog
dll_vip_delete_at_addr_seq delete_seq = dll_vip_delete_at_addr_seq::type_id::create("delete_seq");
delete_seq.num_deletes = 3;
delete_seq.start(env.get_sequencer());
```

**Delete at Index:**
```systemverilog
dll_vip_delete_at_index_seq delete_seq = dll_vip_delete_at_index_seq::type_id::create("delete_seq");
delete_seq.num_deletes = 3;
delete_seq.start(env.get_sequencer());
```

**Delete by Value:**
```systemverilog
dll_vip_delete_value_seq delete_seq = dll_vip_delete_value_seq::type_id::create("delete_seq");
delete_seq.num_deletes = 2;
delete_seq.start(env.get_sequencer());
```

## 🧪 Available Tests

### 1. Simple Test
Basic insert, read, and delete operations:
```bash
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Random Test
Random sequence of insert/read/delete operations:
```bash
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

## 📋 Doubly Linked List Operations

The VIP supports 6 operations matching the DUT (doubly_linked_list.sv):

| Operation | op | Description | Inputs | Outputs |
|-----------|-------|-------------|--------|---------|
| **READ_ADDR** | 3'b000 | Read data at address | addr_in | data_out, pre_node_addr, next_node_addr |
| **INSERT_AT_ADDR** | 3'b001 | Insert at address | addr_in, data_in | head, tail, length |
| **DELETE_VALUE** | 3'b010 | Delete first occurrence of value | data_in | head, tail, length |
| **DELETE_AT_ADDR** | 3'b011 | Delete node at address | addr_in | head, tail, length |
| **INSERT_AT_INDEX** | 3'b101 | Insert at index position | addr_in (index), data_in | head, tail, length |
| **DELETE_AT_INDEX** | 3'b111 | Delete at index position | addr_in (index) | head, tail, length |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity for READ operations
- ✅ Correct list length after INSERT/DELETE
- ✅ INSERT when full behavior
- ✅ READ/DELETE when empty behavior
- ✅ Address-based operations vs index-based operations
- ✅ DELETE_VALUE finds correct first occurrence
- ✅ Fault flag correctness
- ✅ Head/tail pointer management

## 📊 Test Coverage Comparison

| tb/sv/tb.sv | UVM VIP Equivalent | Description |
|-------------|-------------------|-------------|
| `read_n_front()` (line 151) | `dll_vip_read_seq` | Read from front (head) |
| `read_n_back()` (line 219) | `dll_vip_read_seq` | Read from back (tail) |
| Insert operations | `dll_vip_insert_at_addr_seq` | Insert at address |
| Insert operations | `dll_vip_insert_at_index_seq` | Insert at index |
| Delete operations | `dll_vip_delete_at_addr_seq` | Delete at address |
| Delete operations | `dll_vip_delete_at_index_seq` | Delete at index |
| Delete operations | `dll_vip_delete_value_seq` | Delete by value |

## 🔧 Key Features

1. **Address-based and Index-based Operations**: Supports both addressing schemes
2. **Doubly Linked Structure**: Tracks both previous and next node addresses
3. **Value-based Deletion**: Can delete nodes by searching for value
4. **Intelligent Scoreboard**: Models linked list with address and data tracking
5. **Fault Detection**: Validates boundary conditions and error flags
6. **Head/Tail Tracking**: Monitors list head and tail pointers

## 🔍 Differences from Singly Linked List

| Aspect | Singly Linked List | Doubly Linked List |
|--------|-------------------|-------------------|
| **Node Structure** | data + next pointer | data + next + previous pointers |
| **Traversal** | Forward only | Forward and backward |
| **Operations** | 8 ops (includes sort, sum) | 6 ops (focus on insert/delete/read) |
| **Address Outputs** | Single next pointer | Both pre and next pointers |
| **Complexity** | Higher (functional ops) | Moderate (structural focus) |

## 🚨 Common Issues & Solutions

### Issue: Interface signal width mismatch
**Solution:** Update `dll_vip_if.sv` lines 9-19 to match your DLL's parameters:
```systemverilog
logic [DATA_WIDTH-1:0] data_in;
logic [ADDR_WIDTH-1:0] addr_in;
logic [DATA_WIDTH-1:0] data_out;
logic [ADDR_WIDTH-1:0] pre_node_addr;
logic [ADDR_WIDTH-1:0] next_node_addr;
```

### Issue: Address vs Index confusion
**Solution:**
- **Address operations (op[2]==0)**: Use actual node addresses from DUT
- **Index operations (op[2]==1)**: Use sequential index (0, 1, 2, ...)

### Future Work
- Add assertions for doubly-linked integrity (prev->next consistency)
- Add functional coverage for:
  - Insert/delete at head/tail/middle
  - Forward vs backward traversal
  - Empty to full transitions
- Enhanced scoreboard to track full doubly-linked structure

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        dll_vip_insert_at_index_seq insert_seq;
        dll_vip_read_seq read_seq;
        dll_vip_delete_value_seq delete_seq;

        phase.raise_objection(this);

        // Build a list
        insert_seq = dll_vip_insert_at_index_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 5;
        insert_seq.start(env.get_sequencer());

        #500ns;

        // Read from front to back
        read_seq = dll_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.start(env.get_sequencer());

        #500ns;

        // Delete specific values
        delete_seq = dll_vip_delete_value_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 2;
        delete_seq.start(env.get_sequencer());

        #500ns;
        phase.drop_objection(this);
    endtask
endclass
```

## 🎯 Key Characteristics

- **Bidirectional Traversal**: Can navigate both forward (head→tail) and backward (tail→head)
- **Address Management**: Internal addresses managed by DUT, not sequential
- **Flexible Insert/Delete**: Supports both address-based and index-based operations
- **Value Search**: Can find and delete nodes by data value

**Happy Verifying! 🚀**

*This VIP demonstrates advanced verification of pointer-based data structures with UVM.*
