# Development In Progress!!

# FIFO (Queue) UVM VIP (Verification IP) User Guide
## 📁 Directory Structure

```
uvm/
├── src/                           # Core VIP source files
│   ├── fifo_vip_pkg.sv           # Main package + types/enums
│   ├── fifo_vip_config.sv        # Configuration class
│   └── fifo_vip_seq_item.sv      # Transaction definitions
├── agent/                         # Agent layer components
│   ├── fifo_vip_driver.sv        # Driver implementation
│   ├── fifo_vip_monitor.sv       # Monitor implementation
│   ├── fifo_vip_sequencer.sv     # Sequencer (simple)
│   └── fifo_vip_agent.sv         # Agent wrapper
├── env/                          # Environment layer
│   ├── fifo_vip_env.sv           # Environment
│   └── fifo_vip_scoreboard.sv    # Checking components
├── sequences/                     # Test sequences
│   ├── fifo_vip_base_seq.sv      # Base sequence
│   ├── fifo_vip_write_req_seq.sv # Write sequences
│   └── fifo_vip_read_req_seq.sv  # Read sequences
├── interface/                     # Interface definition
│   └── fifo_vip_if.sv            # Virtual interface
└── tb/                           # Testbench
    ├── tests/
    │   └── base_test.sv          # Base test + simple_test
    └── tb_top.sv                 # Testbench top module
```

## 🚀 Quick Start

**Step 1:** Update Agent Interface with correct internal signals (refer to `fifo_vip_if.sv`) in your top level testbench:
```systemverilog
// Update interface signal widths and connections in tb_top.sv
fifo_vip_if dut_if;
assign dut_if.rst = u_fifo.rst;
assign dut_if.rd_clk = u_fifo.rd_clk;
assign dut_if.wr_clk = u_fifo.wr_clk;
assign dut_if.data_wr = u_fifo.data_wr;
assign dut_if.wr_en = u_fifo.wr_en;
assign dut_if.fifo_full = u_fifo.fifo_full;
assign dut_if.data_rd = u_fifo.data_rd;
assign dut_if.rd_en = u_fifo.rd_en;
assign dut_if.fifo_empty = u_fifo.fifo_empty;

// Set interface in config DB
uvm_config_db#(virtual fifo_vip_if)::set(null, "*", "fifo_vip_vif", dut_if);
```

**Step 2:** Update DUT parameters/configuration (refer to `fifo_vip_config.sv`) in your test:
```systemverilog
// In your test's build_phase()
cfg = fifo_vip_config::type_id::create("cfg");
cfg.DEPTH = 16;        // Match your FIFO depth
cfg.DATA_WIDTH = 8;    // Match your data width
cfg.ASYNC = 1;         // 1=async clocks, 0=sync
cfg.RD_BUFFER = 1;     // 1=buffered read, 0=combinational

// Set config in database
uvm_config_db#(fifo_vip_config)::set(this, "*", "fifo_vip_cfg", cfg);
```

**Step 3:** Agent instantiation in your environment (refer to `fifo_vip_env.sv`):
```systemverilog
// Create FIFO VIP environment
fifo_env = fifo_vip_env::type_id::create("fifo_env", this);
````

##🚀 Available Sequences

**Write Sequence:**
```systemverilog
fifo_vip_write_req_seq wr_seq = fifo_vip_write_req_seq::type_id::create("wr_seq");
wr_seq.num_writes = 10;
wr_seq.start(env.get_wr_sequencer());
```

**Read Sequence:**
```systemverilog
fifo_vip_read_req_seq rd_seq = fifo_vip_read_req_seq::type_id::create("rd_seq");
rd_seq.num_reads = 10;
rd_seq.start(env.get_rd_sequencer());
```

## ✅ Self-Checking Features
- ✅ Data integrity through FIFO
- ✅ Write when full behavior
- ✅ Read when empty behavior  
- ✅ FIFO flag correctness
- ✅ Transaction success/failure

## 🚨 Common Issues & Solutions

### Future Work
Add assertions to `fifo_vip_if.sv` or create a separate checker component.
Add coverage 

**Happy Verifying! 🚀**

*This VIP follows UVM best practices while keeping complexity minimal for ease of use and learning.*
