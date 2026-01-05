# Table UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── table_vip_pkg.sv                      [Main package + enums]
│   ├── table_vip_config.sv                   [Configuration class]
│   └── table_vip_seq_item.sv                 [Transaction definitions]
├── interface/                                 [Interface definition]
│   └── table_vip_if.sv                       [Virtual interface]
├── agent/                                     [Agent layer components]
│   ├── table_vip_driver.sv                   [Driver implementation]
│   ├── table_vip_monitor.sv                  [Monitor implementation]
│   ├── table_vip_sequencer.sv                [Sequencer]
│   └── table_vip_agent.sv                    [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── table_vip_env.sv                      [Environment]
│   └── table_vip_scoreboard.sv               [Checking with table model]
├── sequences/                                 [Test sequences]
│   ├── table_vip_base_seq.sv                 [Base sequence]
│   ├── table_vip_write_seq.sv                [Write sequence]
│   └── table_vip_read_seq.sv                 [Read sequence]
└── sim/                                       [Testbench]
    ├── tb_top.sv                              [Testbench top module]
    └── tests/
        ├── table_vip_base_test.sv             [Base test class]
        └── table_vip_simple_test.sv           [Simple, random & parallel tests]
```

## 🚀 Quick Start

**Step 1:** Update interface signals in your testbench:
```systemverilog
table_vip_if dut_if(clk);
// Connect to DUT
uvm_config_db#(virtual table_vip_if)::set(null, "*", "table_vip_vif", dut_if);
```

**Step 2:** Configure DUT parameters in your test:
```systemverilog
cfg = table_vip_config::type_id::create("cfg");
cfg.TABLE_SIZE = 32;
cfg.DATA_WIDTH = 8;
cfg.INPUT_RATE = 2;
cfg.OUTPUT_RATE = 2;
uvm_config_db#(table_vip_config)::set(this, "*", "table_vip_cfg", cfg);
```

**Step 3:** Create environment:
```systemverilog
table_env = table_vip_env::type_id::create("table_env", this);
```

## 🚀 Available Sequences

**Write:**
```systemverilog
table_vip_write_seq write_seq = table_vip_write_seq::type_id::create("write_seq");
write_seq.num_writes = 10;
write_seq.start(env.get_sequencer());
```

**Read:**
```systemverilog
table_vip_read_seq read_seq = table_vip_read_seq::type_id::create("read_seq");
read_seq.num_reads = 10;
read_seq.start(env.get_sequencer());
```

## 🧪 Available Tests

### 1. Simple Test
Basic write and read operations:
```bash
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Random Test
Random sequence of write/read operations:
```bash
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

### 3. Parallel Access Test
Stress test with parallel multi-port accesses:
```bash
vsim -c +UVM_TESTNAME=parallel_access_test -do "run -all; quit"
```

## 📋 Table Operations

The VIP supports 2 operations matching the DUT (table_top.sv):

| Operation | Description | Inputs | Outputs | Parallelism |
|-----------|-------------|--------|---------|-------------|
| **WRITE** | Write data to table | wr_en[1:0], index_wr, data_wr | - | 2 simultaneous writes |
| **READ** | Read data from table | rd_en, index_rd | data_rd | 2 simultaneous reads |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ WRITE operations update table correctly
- ✅ READ operations return correct data
- ✅ Parallel writes to different indices
- ✅ Parallel reads from different indices
- ✅ Read-after-write data integrity
- ✅ Overall table consistency

## 🔧 Key Features

1. **Multi-Port Access**: Supports 2 simultaneous writes and 2 simultaneous reads per cycle
2. **Simple Array Structure**: Direct index-based access (no hashing or chaining)
3. **Configurable Size**: TABLE_SIZE parameter (default 32 entries)
4. **Intelligent Scoreboard**: Models table with SystemVerilog array
5. **Parallel Verification**: Checks multiple operations per transaction

## 📊 Table Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| TABLE_SIZE | 32 | Number of table entries |
| DATA_WIDTH | 8 | Width of data in bits |
| INPUT_RATE | 2 | Number of parallel write ports |
| OUTPUT_RATE | 2 | Number of parallel read ports |

**Throughput:**
- Write: Up to 2 entries per cycle
- Read: Up to 2 entries per cycle

## 🔍 Multi-Port Access

The table supports **parallel multi-port access**:

### Parallel Writes:
```systemverilog
// Single transaction can write to 2 different indices
wr_en = 2'b11;              // Enable both write ports
index_wr = {5'd10, 5'd5};   // Write to index 5 and 10
data_wr = {8'hBB, 8'hAA};   // Data 0xAA to index 5, 0xBB to index 10
```

### Parallel Reads:
```systemverilog
// Single transaction can read from 2 different indices
rd_en = 1'b1;               // Enable read
index_rd = {5'd10, 5'd5};   // Read from index 5 and 10
// Next cycle: data_rd = {data[10], data[5]}
```

## 🚨 Common Issues & Solutions

### Issue: Interface signal width mismatch
**Solution:** Update `table_vip_if.sv` lines 7-14 to match your table's parameters:
```systemverilog
logic [INPUT_RATE-1:0] wr_en;
logic [INPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_wr;
logic [INPUT_RATE*DATA_WIDTH-1:0] data_wr;
logic [OUTPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_rd;
logic [OUTPUT_RATE*DATA_WIDTH-1:0] data_rd;
```

### Issue: Read returns wrong data
**Solution:** Ensure:
- Write occurred at least 1 cycle before read
- Correct index is used
- Reset properly initializes table to 0

### Issue: Parallel write conflict
**Solution:** The design supports writing to **different** indices simultaneously. Writing to the **same** index with both ports may cause conflict (design-dependent behavior).

### Future Work
- Add assertions for simultaneous access to same index
- Add functional coverage for:
  - Write enable patterns (00, 01, 10, 11)
  - Index distribution (sequential vs random)
  - Parallel access patterns
- Performance analysis of multi-port utilization
- Add configurable INPUT_RATE and OUTPUT_RATE support

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        table_vip_write_seq write_seq;
        table_vip_read_seq read_seq;

        phase.raise_objection(this);

        // Fill table with parallel writes
        write_seq = table_vip_write_seq::type_id::create("write_seq");
        write_seq.num_writes = 16;  // 16 transactions = 32 writes total
        write_seq.start(env.get_sequencer());

        #500ns;

        // Read back with parallel reads
        read_seq = table_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 16;  // 16 transactions = 32 reads total
        read_seq.start(env.get_sequencer());

        #500ns;
        phase.drop_objection(this);
    endtask
endclass
```

## 🎯 Key Characteristics

- **Multi-Port Architecture**: 2-write, 2-read ports for high throughput
- **Simple Access**: Direct index-based addressing (no complex logic)
- **Fast Operation**: Single-cycle read, single-cycle write
- **Parallel Efficiency**: Can fill/read entire table in 16 cycles (vs 32 for single-port)

## 📈 Performance Characteristics

**Throughput:**
- Single-port equivalent: 1 operation per cycle
- Multi-port actual: 2 writes OR 2 reads per cycle
- Efficiency gain: 2× throughput

**Latency:**
- WRITE: 1 cycle (data available next cycle)
- READ: 1 cycle (data available next cycle)

**Access Patterns:**
- Sequential: Fill table[0-31] in 16 write transactions
- Random: Any index accessible each cycle
- Parallel: Two independent accesses per cycle

## 🔬 Parallel Access Test Strategy

The `parallel_access_test` specifically stresses multi-port functionality:

```systemverilog
// Each write transaction uses both write ports (wr_en = 2'b11)
// 20 transactions × 2 writes = 40 total writes
write_seq.num_writes = 20;

// Each read transaction uses both read ports
// 20 transactions × 2 reads = 40 total reads
read_seq.num_reads = 20;
```

This tests:
- Both write ports active simultaneously
- Both read ports active simultaneously
- No conflicts when accessing different indices
- Data integrity with parallel operations

## 🔍 Differences from Hash Table

| Aspect | Table | Hash Table |
|--------|-------|------------|
| **Access Method** | Direct index | Hash function + collision resolution |
| **Key Type** | Integer index (0-31) | Arbitrary 32-bit key |
| **Collision** | None (unique indices) | Possible (multiple keys → same hash) |
| **Complexity** | O(1) guaranteed | O(1) average, O(n) worst case |
| **Multi-Port** | 2 writes, 2 reads | Single operation |
| **Use Case** | Fixed-size array | Key-value mapping |

**Happy Verifying! 🚀**

*This VIP demonstrates verification of multi-port memory structures with parallel access using UVM.*
