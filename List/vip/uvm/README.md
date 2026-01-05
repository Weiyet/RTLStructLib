# Singly Linked List UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── common/                           # Core VIP source files
│   ├── list_vip_pkg.sv              # Main package + types/enums
│   ├── list_vip_config.sv           # Configuration class
│   └── list_vip_seq_item.sv         # Transaction definitions
├── agent/                            # Agent layer components
│   ├── list_vip_driver.sv           # Driver implementation
│   ├── list_vip_monitor.sv          # Monitor implementation
│   ├── list_vip_sequencer.sv        # Sequencer (simple)
│   └── list_vip_agent.sv            # Agent wrapper
├── env/                              # Environment layer
│   ├── list_vip_env.sv              # Environment
│   └── list_vip_scoreboard.sv       # Checking components with list model
├── sequences/                        # Test sequences
│   ├── list_vip_base_seq.sv         # Base sequence
│   ├── list_vip_insert_seq.sv       # Insert sequences
│   ├── list_vip_read_seq.sv         # Read sequences
│   ├── list_vip_delete_seq.sv       # Delete sequences
│   ├── list_vip_find_seq.sv         # Find (search) sequences
│   ├── list_vip_sort_seq.sv         # Sort sequences
│   └── list_vip_sum_seq.sv          # Sum sequence
├── interface/                        # Interface definition
│   └── list_vip_if.sv               # Virtual interface
└── sim/                              # Testbench
    ├── tests/
    │   ├── list_vip_base_test.sv       # Base test class
    │   └── list_vip_simple_test.sv     # Simple, direct_op, and random tests
    └── tb_top.sv                       # Testbench top module
```

## 🚀 Quick Start

**Step 1:** Update Agent Interface signals (refer to `list_vip_if.sv`) in your top level testbench:
```systemverilog
// Update interface signal widths and connections in tb_top.sv
list_vip_if dut_if(clk);
assign dut_if.rst = u_list.rst;
assign dut_if.op_sel = u_list.op_sel;
assign dut_if.op_en = u_list.op_en;
assign dut_if.data_in = u_list.data_in;
assign dut_if.index_in = u_list.index_in;
assign dut_if.data_out = u_list.data_out;
assign dut_if.op_done = u_list.op_done;
assign dut_if.op_in_progress = u_list.op_in_progress;
assign dut_if.op_error = u_list.op_error;
assign dut_if.len = u_list.len;

// Set interface in config DB
uvm_config_db#(virtual list_vip_if)::set(null, "*", "list_vip_vif", dut_if);
```

**Step 2:** Update DUT parameters/configuration (refer to `list_vip_config.sv`) in your test:
```systemverilog
// In your test's build_phase()
cfg = list_vip_config::type_id::create("cfg");
cfg.DATA_WIDTH = 8;      // Match your data width
cfg.LENGTH = 8;          // Match your max list length
cfg.SUM_METHOD = 0;      // 0=parallel, 1=sequential, 2=adder tree

// Set config in database
uvm_config_db#(list_vip_config)::set(this, "*", "list_vip_cfg", cfg);
```

**Step 3:** Agent instantiation in your environment (refer to `list_vip_env.sv`):
```systemverilog
// Create List VIP environment
list_env = list_vip_env::type_id::create("list_env", this);
```

## 🚀 Available Sequences

The VIP provides sequences for all 8 list operations:

**Insert Sequence:**
```systemverilog
list_vip_insert_seq insert_seq = list_vip_insert_seq::type_id::create("insert_seq");
insert_seq.num_inserts = 5;
insert_seq.random_index = 0;  // 0=append, 1=random indices
insert_seq.start(env.get_sequencer());
```

**Read Sequence:**
```systemverilog
list_vip_read_seq read_seq = list_vip_read_seq::type_id::create("read_seq");
read_seq.num_reads = 5;
read_seq.sequential = 1;  // 1=sequential, 0=random indices
read_seq.start(env.get_sequencer());
```

**Delete Sequence:**
```systemverilog
list_vip_delete_seq delete_seq = list_vip_delete_seq::type_id::create("delete_seq");
delete_seq.num_deletes = 3;
delete_seq.start(env.get_sequencer());
```

**Find First Index Sequence:**
```systemverilog
list_vip_find_1st_seq find_seq = list_vip_find_1st_seq::type_id::create("find_seq");
find_seq.num_searches = 2;
find_seq.start(env.get_sequencer());
```

**Find All Indices Sequence:**
```systemverilog
list_vip_find_all_seq find_all_seq = list_vip_find_all_seq::type_id::create("find_all_seq");
find_all_seq.num_searches = 1;
find_all_seq.start(env.get_sequencer());
```

**Sum Sequence:**
```systemverilog
list_vip_sum_seq sum_seq = list_vip_sum_seq::type_id::create("sum_seq");
sum_seq.start(env.get_sequencer());
```

**Sort Ascending:**
```systemverilog
list_vip_sort_asc_seq sort_seq = list_vip_sort_asc_seq::type_id::create("sort_seq");
sort_seq.start(env.get_sequencer());
```

**Sort Descending:**
```systemverilog
list_vip_sort_des_seq sort_seq = list_vip_sort_des_seq::type_id::create("sort_seq");
sort_seq.start(env.get_sequencer());
```

## 🧪 Available Tests

The VIP includes three pre-built tests matching the testing patterns from `tb/sv/tb.sv`:

### 1. Simple Test
Basic insert, read, delete, and sum operations:
```bash
# Run simple test
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Direct Operation Test
Comprehensive test exercising all 8 operations (mirrors `tb.sv` `direct_op_test`):
```bash
# Run direct operation test
vsim -c +UVM_TESTNAME=direct_op_test -do "run -all; quit"
```

### 3. Random Test
Random sequence of insert/read/delete/search operations:
```bash
# Run random test
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

## 📋 List Operations Reference

The List VIP supports 8 operations matching the DUT (list.sv):

| Operation | op_sel | Description | Inputs | Outputs |
|-----------|--------|-------------|--------|---------|
| **READ** | 3'b000 | Read data at index | index_in | data_out |
| **INSERT** | 3'b001 | Insert data at index | index_in, data_in | len |
| **FIND_ALL** | 3'b010 | Find all indices of value | data_in | data_out (multiple) |
| **FIND_1ST** | 3'b011 | Find first index of value | data_in | data_out (index) |
| **SUM** | 3'b100 | Sum all elements | - | data_out (sum) |
| **SORT_ASC** | 3'b101 | Sort ascending | - | (modifies list) |
| **SORT_DES** | 3'b110 | Sort descending | - | (modifies list) |
| **DELETE** | 3'b111 | Delete element at index | index_in | len |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity for READ operations
- ✅ Correct list length after INSERT/DELETE
- ✅ INSERT when full behavior
- ✅ READ/DELETE when out of bounds behavior
- ✅ FIND_1ST returns correct first index
- ✅ SUM computes correct total
- ✅ SORT correctly reorders elements
- ✅ Error flag correctness
- ✅ List state consistency

## 📊 Test Coverage Comparison

The UVM VIP tests provide equivalent coverage to the original testbench:

| tb/sv/tb.sv | UVM VIP Equivalent | Description |
|-------------|-------------------|-------------|
| `insert()` (line 190) | `list_vip_insert_seq` | Insert at index or append |
| `read()` (line 111) | `list_vip_read_seq` | Read element at index |
| `delete()` (line 231) | `list_vip_delete_seq` | Delete element at index |
| `find_1st_index()` (line 350) | `list_vip_find_1st_seq` | Find first occurrence |
| `find_all_index()` (line 385) | `list_vip_find_all_seq` | Find all occurrences |
| `sum()` (line 325) | `list_vip_sum_seq` | Sum all elements |
| `sort_acending()` (line 267) | `list_vip_sort_asc_seq` | Sort ascending |
| `sort_desending()` (line 295) | `list_vip_sort_des_seq` | Sort descending |
| `direct_op_test()` (line 433) | `direct_op_test` class | Comprehensive operation test |

## 🔧 Key Features

1. **Comprehensive Operation Coverage**: All 8 list operations supported
2. **Intelligent Scoreboard**: Uses SystemVerilog queue to model list behavior
3. **Flexible Sequences**: Configurable for different test scenarios
4. **Error Checking**: Validates boundary conditions and error flags
5. **Reusable**: Easy to integrate into any testbench

## 🔍 Differences from FIFO/LIFO VIPs

| Aspect | FIFO/LIFO VIP | List VIP |
|--------|---------------|----------|
| **Operations** | 2-3 basic ops (push/pop/read/write) | 8 complex ops (insert/delete/search/sort/sum) |
| **Data Structure** | Fixed-size circular buffer | Dynamic list with variable length |
| **Scoreboard Model** | Simple queue | Full list model with insert/delete/search |
| **Sequences** | 2-3 sequence types | 7 sequence types (one per operation) |
| **Complexity** | Low | High |
| **State Tracking** | Depth only | Depth + content + order |

## 🚨 Common Issues & Solutions

### Issue: Interface signal width mismatch
**Solution:** Update `list_vip_if.sv` lines 14-21 to match your List's parameters:
```systemverilog
logic [DATA_WIDTH-1:0] data_in;
logic [LENGTH_WIDTH-1:0] index_in;
logic [DATA_OUT_WIDTH-1:0] data_out;
logic [$clog2(LENGTH+1)-1:0] len;
```

### Issue: Config parameters don't match DUT
**Solution:** Ensure `list_vip_config.sv` parameters match your DUT instantiation in `tb_top.sv`

### Issue: FIND_ALL sequence timing
**Solution:** FIND_ALL can take multiple cycles. The driver waits for `op_in_progress` to deassert.

### Future Work
- Add assertions to `list_vip_if.sv` for protocol checking
- Add functional coverage for:
  - Operation distribution
  - List length transitions
  - Boundary condition hits (empty, full)
  - Sort before/after patterns
  - Sequential operation patterns
- Enhanced FIND_ALL tracking to capture all reported indices

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        list_vip_insert_seq insert_seq;
        list_vip_sort_asc_seq sort_seq;
        list_vip_read_seq read_seq;
        list_vip_sum_seq sum_seq;

        phase.raise_objection(this);

        // Build a list
        insert_seq = list_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = cfg.LENGTH - 1;
        insert_seq.start(env.get_sequencer());

        #200ns;

        // Sort it
        sort_seq = list_vip_sort_asc_seq::type_id::create("sort_seq");
        sort_seq.start(env.get_sequencer());

        #500ns;

        // Read sorted values
        read_seq = list_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = cfg.LENGTH - 1;
        read_seq.sequential = 1;
        read_seq.start(env.get_sequencer());

        #500ns;

        // Calculate sum
        sum_seq = list_vip_sum_seq::type_id::create("sum_seq");
        sum_seq.start(env.get_sequencer());

        #200ns;
        phase.drop_objection(this);
    endtask
endclass
```

**Happy Verifying! 🚀**

*This VIP follows UVM best practices while demonstrating advanced verification techniques for complex data structures.*
