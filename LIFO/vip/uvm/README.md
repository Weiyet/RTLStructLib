# LIFO (Stack) UVM VIP (Verification IP) User Guide

## 📁 Directory Structure

```
uvm/
├── common/                        # Core VIP source files
│   ├── lifo_vip_pkg.sv           # Main package + types/enums
│   ├── lifo_vip_config.sv        # Configuration class
│   └── lifo_vip_seq_item.sv      # Transaction definitions
├── agent/                         # Agent layer components
│   ├── lifo_vip_driver.sv        # Driver implementation
│   ├── lifo_vip_monitor.sv       # Monitor implementation
│   ├── lifo_vip_sequencer.sv     # Sequencer (simple)
│   └── lifo_vip_agent.sv         # Agent wrapper
├── env/                          # Environment layer
│   ├── lifo_vip_env.sv           # Environment
│   └── lifo_vip_scoreboard.sv    # Checking components
├── sequences/                     # Test sequences
│   ├── lifo_vip_base_seq.sv      # Base sequence
│   ├── lifo_vip_push_seq.sv      # Push sequences
│   └── lifo_vip_pop_seq.sv       # Pop sequences
├── interface/                     # Interface definition
│   └── lifo_vip_if.sv            # Virtual interface
└── sim/                           # Testbench
    ├── tests/
    │   ├── lifo_vip_base_test.sv    # Base test class
    │   └── lifo_vip_simple_test.sv  # Simple test + random test + full/empty test
    └── tb_top.sv                    # Testbench top module
```

## 🚀 Quick Start

**Step 1:** Update Agent Interface with correct internal signals (refer to `lifo_vip_if.sv`) in your top level testbench:
```systemverilog
// Update interface signal widths and connections in tb_top.sv
lifo_vip_if dut_if(clk);
assign dut_if.rst = u_lifo.rst;
assign dut_if.data_wr = u_lifo.data_wr;
assign dut_if.wr_en = u_lifo.wr_en;
assign dut_if.lifo_full = u_lifo.lifo_full;
assign dut_if.data_rd = u_lifo.data_rd;
assign dut_if.rd_en = u_lifo.rd_en;
assign dut_if.lifo_empty = u_lifo.lifo_empty;

// Set interface in config DB
uvm_config_db#(virtual lifo_vip_if)::set(null, "*", "lifo_vip_vif", dut_if);
```

**Step 2:** Update DUT parameters/configuration (refer to `lifo_vip_config.sv`) in your test:
```systemverilog
// In your test's build_phase()
cfg = lifo_vip_config::type_id::create("cfg");
cfg.DEPTH = 12;        // Match your LIFO depth
cfg.DATA_WIDTH = 8;    // Match your data width

// Set config in database
uvm_config_db#(lifo_vip_config)::set(this, "*", "lifo_vip_cfg", cfg);
```

**Step 3:** Agent instantiation in your environment (refer to `lifo_vip_env.sv`):
```systemverilog
// Create LIFO VIP environment
lifo_env = lifo_vip_env::type_id::create("lifo_env", this);
```

## 🚀 Available Sequences

**Push Sequence:**
```systemverilog
lifo_vip_push_seq push_seq = lifo_vip_push_seq::type_id::create("push_seq");
push_seq.num_pushes = 10;
push_seq.start(env.get_sequencer());
```

**Pop Sequence:**
```systemverilog
lifo_vip_pop_seq pop_seq = lifo_vip_pop_seq::type_id::create("pop_seq");
pop_seq.num_pops = 10;
pop_seq.start(env.get_sequencer());
```

## 🧪 Available Tests

The VIP includes three pre-built tests that match the testing patterns from `tb/sv/tb.sv`:

### 1. Simple Test
Basic push and pop operations:
```bash
# Run simple test
vsim -c +UVM_TESTNAME=simple_test -do "run -all; quit"
```

### 2. Random Test
Random sequence of push/pop operations (similar to `lifo_random_op_test` in tb.sv):
```bash
# Run random test
vsim -c +UVM_TESTNAME=random_test -do "run -all; quit"
```

### 3. Full/Empty Test
Tests boundary conditions - filling LIFO completely and emptying it:
```bash
# Run full/empty test
vsim -c +UVM_TESTNAME=full_empty_test -do "run -all; quit"
```

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity through LIFO (Last-In-First-Out order)
- ✅ Push when full behavior
- ✅ Pop when empty behavior
- ✅ LIFO flag correctness (full/empty)
- ✅ Transaction success/failure
- ✅ LIFO depth tracking

## 📊 Test Coverage Comparison

The UVM VIP tests provide equivalent coverage to the original testbench:

| tb/sv/tb.sv | UVM VIP Test | Description |
|-------------|--------------|-------------|
| `lifo_write()` | `lifo_vip_push_seq` | Push data to LIFO |
| `lifo_read()` | `lifo_vip_pop_seq` | Pop data from LIFO |
| `lifo_random_op_test()` | `random_test` | Random push/pop/bypass operations |
| `lifo_simul_read_write()` | Monitor bypass detection | Simultaneous read/write |
| Full/empty flag checking | `full_empty_test` + scoreboard | Boundary condition testing |

## 🔧 Key Differences from FIFO VIP

1. **Single Clock Domain**: LIFO uses single clock (synchronous), unlike FIFO's dual-clock support
2. **Operation Types**:
   - FIFO: `WRITE`, `READ`, `IDLE`
   - LIFO: `PUSH`, `POP`, `IDLE`
3. **Data Order**:
   - FIFO: First-In-First-Out (queue model)
   - LIFO: Last-In-First-Out (stack model - `push_back`/`pop_back`)
4. **Bypass Mode**: LIFO supports simultaneous push/pop (bypass operation)
5. **Single Agent**: One agent handles all operations (vs separate read/write agents in FIFO)

## 🚨 Common Issues & Solutions

### Issue: Interface signal width mismatch
**Solution:** Update `lifo_vip_if.sv` line 16-17 to match your LIFO's `DATA_WIDTH`:
```systemverilog
logic [DATA_WIDTH-1:0] data_wr;
logic [DATA_WIDTH-1:0] data_rd;
```

### Issue: Config parameters don't match DUT
**Solution:** Ensure `lifo_vip_config.sv` parameters match your DUT instantiation in `tb_top.sv`

### Future Work
- Add assertions to `lifo_vip_if.sv` or create a separate checker component
- Add functional coverage for:
  - Push/pop distribution
  - Full/empty transitions
  - Bypass operations
  - Back-to-back operations

## 📚 Example Usage

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    task run_phase(uvm_phase phase);
        lifo_vip_push_seq push_seq;
        lifo_vip_pop_seq pop_seq;

        phase.raise_objection(this);

        // Fill LIFO
        push_seq = lifo_vip_push_seq::type_id::create("push_seq");
        push_seq.num_pushes = cfg.DEPTH;
        push_seq.start(env.get_sequencer());

        #100ns;

        // Empty LIFO and verify LIFO order
        pop_seq = lifo_vip_pop_seq::type_id::create("pop_seq");
        pop_seq.num_pops = cfg.DEPTH;
        pop_seq.start(env.get_sequencer());

        #100ns;
        phase.drop_objection(this);
    endtask
endclass
```

**Happy Verifying! 🚀**

*This VIP follows UVM best practices while keeping complexity minimal for ease of use and learning.*
