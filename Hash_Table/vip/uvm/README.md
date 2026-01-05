# Hash Table UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── ht_vip_pkg.sv                         [Main package + enums]
│   ├── ht_vip_config.sv                      [Configuration class]
│   └── ht_vip_seq_item.sv                    [Transaction definitions]
├── interface/                                 [Interface definition]
│   └── ht_vip_if.sv                          [Virtual interface]
├── agent/                                     [Agent layer components]
│   ├── ht_vip_driver.sv                      [Driver implementation]
│   ├── ht_vip_monitor.sv                     [Monitor implementation]
│   ├── ht_vip_sequencer.sv                   [Sequencer]
│   └── ht_vip_agent.sv                       [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── ht_vip_env.sv                         [Environment]
│   └── ht_vip_scoreboard.sv                  [Checking with hash table model]
├── sequences/                                 [Test sequences]
│   ├── ht_vip_base_seq.sv                    [Base sequence]
│   ├── ht_vip_insert_seq.sv                  [Insert sequence]
│   ├── ht_vip_search_seq.sv                  [Search sequence]
│   └── ht_vip_delete_seq.sv                  [Delete sequence]
└── sim/                                       [Testbench]
    ├── tb_top.sv                              [Testbench top module]
    └── tests/
        ├── ht_vip_base_test.sv                [Base test class]
        └── ht_vip_simple_test.sv              [Simple, random & collision tests]
```

## 🚀 Quick Start

**Step 1:** Update interface signals in your testbench:
```systemverilog
ht_vip_if dut_if(clk);
// Connect to DUT
uvm_config_db#(virtual ht_vip_if)::set(null, "*", "ht_vip_vif", dut_if);
```

**Step 2:** Configure DUT parameters in your test:
```systemverilog
cfg = ht_vip_config::type_id::create("cfg");
cfg.KEY_WIDTH = 32;
cfg.VALUE_WIDTH = 32;
cfg.TOTAL_INDEX = 8;
cfg.CHAINING_SIZE = 4;
cfg.COLLISION_METHOD = "MULTI_STAGE_CHAINING";
cfg.HASH_ALGORITHM = "MODULUS";
uvm_config_db#(ht_vip_config)::set(this, "*", "ht_vip_cfg", cfg);
```

**Step 3:** Create environment:
```systemverilog
ht_env = ht_vip_env::type_id::create("ht_env", this);
```

## 🚀 Available Sequences

**Insert:**
```systemverilog
ht_vip_insert_seq insert_seq = ht_vip_insert_seq::type_id::create("insert_seq");
insert_seq.num_inserts = 10;
insert_seq.start(env.get_sequencer());
```

**Search:**
```systemverilog
ht_vip_search_seq search_seq = ht_vip_search_seq::type_id::create("search_seq");
search_seq.num_searches = 10;
search_seq.start(env.get_sequencer());
```

**Delete:**
```systemverilog
ht_vip_delete_seq delete_seq = ht_vip_delete_seq::type_id::create("delete_seq");
delete_seq.num_deletes = 5;
delete_seq.start(env.get_sequencer());
```

## 🧪 Available Tests

### 1. Simple Test
Basic insert, search, and delete operations:
```bash
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Random Test
Random sequence of insert/search/delete operations:
```bash
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

### 3. Collision Test
Stress test with many inserts to force hash collisions:
```bash
vsim -c +UVM_TESTNAME=collision_test -do "run -all; quit"
```

## 📋 Hash Table Operations

The VIP supports 3 operations matching the DUT (hash_table.sv):

| Operation | op_sel | Description | Inputs | Outputs |
|-----------|--------|-------------|--------|---------|
| **INSERT** | 2'b00 | Insert key-value pair | key_in, value_in | op_done, op_error, collision_count |
| **DELETE** | 2'b01 | Delete key-value pair | key_in | op_done, op_error |
| **SEARCH** | 2'b10 | Search for key | key_in | value_out, op_done, op_error, collision_count |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ INSERT operations succeed when table not full
- ✅ INSERT operations fail when table is full
- ✅ SEARCH returns correct value for existing keys
- ✅ SEARCH fails for non-existent keys
- ✅ DELETE succeeds for existing keys
- ✅ DELETE fails for non-existent keys
- ✅ Error flag correctness
- ✅ Overall hash table integrity

## 🔧 Key Features

1. **Collision Handling**: Supports chaining collision resolution
2. **Hash Algorithms**: Supports MODULUS hash algorithm (extensible for SHA1, FNV1A)
3. **Configurable Size**: TOTAL_INDEX and CHAINING_SIZE parameters
4. **Intelligent Scoreboard**: Models hash table with SystemVerilog associative arrays
5. **Error Detection**: Validates full table and key-not-found conditions
6. **Collision Tracking**: Monitors collision_count output

## 📊 Hash Table Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| KEY_WIDTH | 32 | Width of key in bits |
| VALUE_WIDTH | 32 | Width of value in bits |
| TOTAL_INDEX | 8 | Number of hash table buckets |
| CHAINING_SIZE | 4 | Max chain length per bucket |
| COLLISION_METHOD | "MULTI_STAGE_CHAINING" | Collision resolution method |
| HASH_ALGORITHM | "MODULUS" | Hash function algorithm |

**Maximum Capacity:** TOTAL_INDEX × CHAINING_SIZE = 8 × 4 = 32 entries

## 🔍 Collision Handling

The hash table uses **chaining** to handle collisions:

1. **Hash Function**: `hash_index = key % TOTAL_INDEX`
2. **Collision Resolution**: Multiple keys mapping to same index are stored in a chain
3. **Chain Search**: Linear search through chain to find/insert/delete keys
4. **Collision Count**: DUT outputs number of items in chain

### Example:
- Key 10 → hash_index = 10 % 8 = 2
- Key 18 → hash_index = 18 % 8 = 2 (collision!)
- Both stored at index 2 in chain positions 0 and 1

## 🚨 Common Issues & Solutions

### Issue: Interface signal width mismatch
**Solution:** Update `ht_vip_if.sv` lines 7-14 to match your hash table's parameters:
```systemverilog
logic [KEY_WIDTH-1:0] key_in;
logic [VALUE_WIDTH-1:0] value_in;
logic [VALUE_WIDTH-1:0] value_out;
```

### Issue: Hash collisions causing failures
**Solution:**
- Increase CHAINING_SIZE parameter for more items per bucket
- Increase TOTAL_INDEX for more buckets
- Use different hash algorithm for better distribution

### Issue: Search failing after insert
**Solution:** Check that:
- Same key is used for insert and search
- Sufficient delay between operations for op_done
- Table not full (INSERT would fail)

### Future Work
- Add support for SHA1 and FNV1A hash algorithms
- Add support for LINEAR_PROBING collision method
- Add functional coverage for:
  - Hash distribution uniformity
  - Collision chain lengths
  - Full table scenarios
- Performance analysis of different hash algorithms

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        ht_vip_insert_seq insert_seq;
        ht_vip_search_seq search_seq;
        ht_vip_delete_seq delete_seq;

        phase.raise_objection(this);

        // Build hash table
        insert_seq = ht_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 15;
        insert_seq.start(env.get_sequencer());

        #500ns;

        // Search for keys
        search_seq = ht_vip_search_seq::type_id::create("search_seq");
        search_seq.num_searches = 15;
        search_seq.start(env.get_sequencer());

        #500ns;

        // Delete some entries
        delete_seq = ht_vip_delete_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 5;
        delete_seq.start(env.get_sequencer());

        #500ns;
        phase.drop_objection(this);
    endtask
endclass
```

## 🎯 Key Characteristics

- **Fast Lookup**: O(1) average case for insert/search/delete
- **Collision Handling**: Chaining method with configurable chain size
- **Key-Value Storage**: Maps 32-bit keys to 32-bit values
- **Error Reporting**: Signals table full and key-not-found conditions
- **Collision Monitoring**: Tracks number of collisions per operation

## 📈 Performance Considerations

**Best Case:** No collisions
- INSERT: 1 cycle to hash + 1 cycle to store
- SEARCH: 1 cycle to hash + 1 cycle to read
- DELETE: 1 cycle to hash + 1 cycle to delete

**Worst Case:** Full chain
- INSERT: 1 cycle to hash + CHAINING_SIZE cycles to search
- SEARCH: 1 cycle to hash + CHAINING_SIZE cycles to search
- DELETE: 1 cycle to hash + CHAINING_SIZE cycles to search + shift operations

## 🔬 Collision Test Strategy

The `collision_test` specifically stresses the hash table:

```systemverilog
// Insert 30 items into 8 buckets (avg 3.75 items per bucket)
// With CHAINING_SIZE=4, this should trigger near-full conditions
insert_seq.num_inserts = 30;
```

This tests:
- Chain management
- Full bucket detection
- Search through chains
- Collision counter accuracy

**Happy Verifying! 🚀**

*This VIP demonstrates advanced verification of hash table data structures with collision handling using UVM.*
