# Dual Edge Flip-Flop UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── deff_vip_pkg.sv                       [Main package]
│   ├── deff_vip_config.sv                    [Configuration class]
│   └── deff_vip_seq_item.sv                  [Transaction definitions]
├── interface/                                 [Interface definition]
│   └── deff_vip_if.sv                        [Virtual interface]
├── agent/                                     [Agent layer components]
│   ├── deff_vip_driver.sv                    [Driver implementation]
│   ├── deff_vip_monitor.sv                   [Monitor implementation]
│   ├── deff_vip_sequencer.sv                 [Sequencer]
│   └── deff_vip_agent.sv                     [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── deff_vip_env.sv                       [Environment]
│   └── deff_vip_scoreboard.sv                [Checking with dual-edge model]
├── sequences/                                 [Test sequences]
│   ├── deff_vip_base_seq.sv                  [Base sequence]
│   └── deff_vip_random_seq.sv                [Random, pos-edge, neg-edge, dual-edge]
└── sim/                                       [Testbench]
    ├── tb_top.sv                              [Testbench top module]
    └── tests/
        ├── deff_vip_base_test.sv              [Base test class]
        └── deff_vip_simple_test.sv            [Multiple test scenarios]
```

## 🚀 Quick Start

**Step 1:** Update interface signals in your testbench:
```systemverilog
deff_vip_if dut_if(clk);
// Connect to DUT
uvm_config_db#(virtual deff_vip_if)::set(null, "*", "deff_vip_vif", dut_if);
```

**Step 2:** Configure DUT parameters in your test:
```systemverilog
cfg = deff_vip_config::type_id::create("cfg");
cfg.DATA_WIDTH = 8;
cfg.RESET_VALUE = 8'h00;
uvm_config_db#(deff_vip_config)::set(this, "*", "deff_vip_cfg", cfg);
```

**Step 3:** Create environment:
```systemverilog
deff_env = deff_vip_env::type_id::create("deff_env", this);
```

## 🚀 Available Sequences

**Random (Both Edges):**
```systemverilog
deff_vip_random_seq seq = deff_vip_random_seq::type_id::create("seq");
seq.num_items = 50;
seq.start(env.get_sequencer());
```

**Positive Edge Only:**
```systemverilog
deff_vip_pos_edge_only_seq seq = deff_vip_pos_edge_only_seq::type_id::create("seq");
seq.num_items = 30;
seq.start(env.get_sequencer());
```

**Negative Edge Only:**
```systemverilog
deff_vip_neg_edge_only_seq seq = deff_vip_neg_edge_only_seq::type_id::create("seq");
seq.num_items = 30;
seq.start(env.get_sequencer());
```

**Dual Edge (Both Active):**
```systemverilog
deff_vip_dual_edge_seq seq = deff_vip_dual_edge_seq::type_id::create("seq");
seq.num_items = 30;
seq.start(env.get_sequencer());
```

## 🧪 Available Tests

### 1. Simple Test
Random transactions with mixed edge enables:
```bash
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Positive Edge Test
Only positive edge latching active:
```bash
vsim -c +UVM_TESTNAME=pos_edge_test -do "run -all; quit"
```

### 3. Negative Edge Test
Only negative edge latching active:
```bash
vsim -c +UVM_TESTNAME=neg_edge_test -do "run -all; quit"
```

### 4. Dual Edge Test
Both edges active simultaneously:
```bash
vsim -c +UVM_TESTNAME=dual_edge_test -do "run -all; quit"
```

### 5. Random Test
Mix of all edge configurations:
```bash
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

## 📋 Dual Edge FF Operation

The Dual Edge FF latches data on **both** positive and negative clock edges to achieve **double data rate**:

| Signal | Description | Width |
|--------|-------------|-------|
| **data_in** | Input data | 8 bits |
| **pos_edge_latch_en** | Enable latching on positive edge (per-bit) | 8 bits |
| **neg_edge_latch_en** | Enable latching on negative edge (per-bit) | 8 bits |
| **data_out** | Output data (XOR of pos and neg registers) | 8 bits |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Correct XOR behavior between pos and neg registers
- ✅ Positive edge latching when enabled
- ✅ Negative edge latching when enabled
- ✅ Per-bit independent latch enable control
- ✅ Reset value initialization
- ✅ Output = q_out_pos XOR q_out_neg

## 🔧 Key Features

1. **Dual-Edge Triggering**: Latches on both rising and falling clock edges
2. **Per-Bit Control**: Independent latch enable for each bit
3. **XOR Output**: Output is XOR of positive and negative edge registers
4. **Double Data Rate**: Can capture data at 2× clock frequency
5. **Synthesizable**: Uses XOR encoding for dual-edge behavior
6. **Intelligent Scoreboard**: Models both pos and neg registers

## 📊 Dual Edge FF Architecture

### Internal Structure:
```
For each bit i:

Positive Edge Path:
  d_in_pos[i] = data_in[i] XOR q_out_neg[i]
  @ posedge clk: if (pos_edge_latch_en[i]) q_out_pos[i] <= d_in_pos[i]

Negative Edge Path:
  d_in_neg[i] = data_in[i] XOR q_out_pos[i]
  @ negedge clk: if (neg_edge_latch_en[i]) q_out_neg[i] <= d_in_neg[i]

Output:
  data_out[i] = q_out_pos[i] XOR q_out_neg[i]
```

### Why XOR Encoding?
The XOR encoding allows **synthesizable** dual-edge behavior:
- Traditional dual-edge FFs need special libraries
- XOR encoding works with standard cells
- Positive and negative edge FFs can be synthesized normally
- XOR gates combine the outputs

## 🔍 Operation Modes

### Mode 1: Positive Edge Only
```systemverilog
pos_edge_latch_en = 8'hFF;  // All bits enabled
neg_edge_latch_en = 8'h00;  // All bits disabled
// Behaves like normal positive-edge FF
```

### Mode 2: Negative Edge Only
```systemverilog
pos_edge_latch_en = 8'h00;  // All bits disabled
neg_edge_latch_en = 8'hFF;  // All bits enabled
// Behaves like negative-edge FF
```

### Mode 3: Dual Edge (DDR)
```systemverilog
pos_edge_latch_en = 8'hFF;  // All bits enabled
neg_edge_latch_en = 8'hFF;  // All bits enabled
// Captures data on BOTH edges (double data rate)
```

### Mode 4: Per-Bit Mixed
```systemverilog
pos_edge_latch_en = 8'hF0;  // Upper nibble on pos edge
neg_edge_latch_en = 8'h0F;  // Lower nibble on neg edge
// Different bits use different edges
```

## 🚨 Common Issues & Solutions

### Issue: Output doesn't match expected
**Solution:** Remember output is **XOR** of two registers:
```systemverilog
data_out = q_out_pos XOR q_out_neg
```
Not a simple register value.

### Issue: Understanding XOR encoding
**Solution:**
- When only pos_edge active: q_out_neg stays 0, so data_out = q_out_pos
- When only neg_edge active: q_out_pos stays at reset, output depends on XOR
- When both active: data toggles between edges

### Issue: Reset behavior
**Solution:**
- q_out_pos resets to RESET_VALUE
- q_out_neg always resets to 0
- Initial data_out = RESET_VALUE XOR 0 = RESET_VALUE

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        deff_vip_pos_edge_only_seq pos_seq;
        deff_vip_neg_edge_only_seq neg_seq;
        deff_vip_dual_edge_seq dual_seq;

        phase.raise_objection(this);

        // Test positive edge latching
        pos_seq = deff_vip_pos_edge_only_seq::type_id::create("pos_seq");
        pos_seq.num_items = 20;
        pos_seq.start(env.get_sequencer());

        #200ns;

        // Test negative edge latching
        neg_seq = deff_vip_neg_edge_only_seq::type_id::create("neg_seq");
        neg_seq.num_items = 20;
        neg_seq.start(env.get_sequencer());

        #200ns;

        // Test dual edge (DDR) mode
        dual_seq = deff_vip_dual_edge_seq::type_id::create("dual_seq");
        dual_seq.num_items = 20;
        dual_seq.start(env.get_sequencer());

        #200ns;
        phase.drop_objection(this);
    endtask
endclass
```

## 🎯 Key Characteristics

- **Dual-Edge Sensitive**: Responds to both rising and falling clock edges
- **XOR-Based Encoding**: Synthesizable implementation of dual-edge behavior
- **Per-Bit Control**: Each bit can independently use pos/neg/both edges
- **Double Data Rate**: Effective 2× data throughput
- **Standard Cell Compatible**: No special library cells required

## 📈 Performance Characteristics

**Effective Frequency:**
- Single edge FF: 1× clock frequency
- Dual edge FF: 2× clock frequency (captures on both edges)

**Example at 40MHz:**
- Clock period: 25ns
- Pos edge: data captured at 0ns, 25ns, 50ns...
- Neg edge: data captured at 12.5ns, 37.5ns, 62.5ns...
- Effective rate: 80 Mega-samples/second

## 🔬 Test Strategy

The test suite covers:

1. **simple_test**: Random mix of edge enables
2. **pos_edge_test**: Verify positive edge path only
3. **neg_edge_test**: Verify negative edge path only
4. **dual_edge_test**: Verify both edges active (DDR mode)
5. **random_test**: Random switching between modes

**Coverage Goals:**
- All 256 combinations of pos_edge_latch_en
- All 256 combinations of neg_edge_latch_en
- Edge transitions (pos→neg, neg→pos, both→single)
- Data patterns (walking 1s, walking 0s, random)

## 🔍 Differences from Standard FF

| Aspect | Standard FF | Dual Edge FF |
|--------|------------|--------------|
| **Edge Sensitivity** | Single edge (pos or neg) | Both edges |
| **Data Rate** | 1× clock | 2× clock |
| **Implementation** | Simple D-FF | XOR-encoded dual registers |
| **Output** | Direct Q | XOR of two registers |
| **Complexity** | Low | Medium |
| **Use Case** | Normal clocking | DDR, high-speed I/O |

## 💡 Applications

The Dual Edge FF is used in:
- **DDR Memory Interfaces**: Data on both edges
- **High-Speed Serial I/O**: Double throughput
- **Clock Domain Crossing**: Phase alignment
- **Video Interfaces**: Pixel clock doubling
- **FPGA I/O Blocks**: Standard DDR support

**Happy Verifying! 🚀**

*This VIP demonstrates verification of dual-edge triggered flip-flops with XOR encoding using UVM.*
