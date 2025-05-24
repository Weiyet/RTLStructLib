# FIFO UVM VIP (Verification IP) (Development In Progress)

A comprehensive SystemVerilog UVM-based Verification IP for FIFO (First-In-First-Out) memory designs.

## Features

### 🚀 **Complete UVM Environment**
- **Configurable Parameters**: Supports different DEPTH, DATA_WIDTH, ASYNC, and RD_BUFFER configurations
- **Reusable Components**: Modular design with separate driver, monitor, agent, and environment
- **Comprehensive Coverage**: Functional coverage for all FIFO operations and corner cases
- **Advanced Scoreboard**: Built-in reference model with automatic checking

### 🎯 **Test Scenarios**
- **Random Operations**: Mixed read/write operations with randomized data
- **Fill/Empty Tests**: Systematic FIFO fill and empty operations
- **Burst Operations**: High-throughput simultaneous read/write testing
- **Corner Cases**: Edge case testing (full/empty conditions, corner data values)
- **Stress Testing**: Back-to-back operations and boundary condition testing

### 📊 **Verification Features**
- **Automatic Checking**: Self-checking testbench with scoreboard
- **Coverage Collection**: Comprehensive functional coverage metrics
- **Multiple Clock Domains**: Support for asynchronous read/write clocks
- **Configurable Buffering**: Support for buffered and unbuffered read modes

## Directory Structure

```
uvm/
│   ├── protocol/
│   │   ├── fifo_vip_pkg.sv            # Main package, types and enums
│   │   ├── fifo_vip_seq_item.sv       # Transaction definitions
│   │   └── fifo_vip_config.sv         # Configuration classes
│   ├── agent/
│   │   ├── fifo_vip_driver.sv         # Driver 
│   │   ├── fifo_vip_monitor.sv        # Monitor 
│   │   ├── fifo_vip_sequencer.sv      # Sequencer
│   │   └── fifo_vip_agent.sv          # Agent wrapper
│   ├── env/
│   │   ├── fifo_vip_env.sv            # Environment
│   │   ├── fifo_vip_scoreboard.sv     # Checking components
│   │   └── fifo_vip_coverage.sv       # Coverage collector
│   ├── sequences/
│   │   ├── fifo_vip_base_seq.sv       # Base sequence
│   │   ├── fifo_vip_write_req_seq.sv  # FIFO Write Request sequences
│   │   ├── fifo_vip_read_req_seq.sv   # FIFO Read Request sequences
│   └── interface/
│       └── fifo_vip_if.sv          # Interface definition
├── tb/
│   ├── tests/
│   │   ├── base_test.sv               # Base test class
│   │   └── example_tests.sv           # Example test cases
│   └── tb_top.sv                      # Example testbench
└── scripts/
    ├── Makefile
    └── run_scripts/
```

## Quick Start

### 1. Setup Environment
```bash
# Set UVM_HOME environment variable
export UVM_HOME=/path/to/uvm/library

# Create directory structure
make setup
```

### 2. Place Your Files
- Copy your FIFO design to `src/fifo.sv`
- Copy the VIP package to `vip/fifo_vip_pkg.sv`
- Copy the testbench to `tb/fifo_tb_top.sv`

### 3. Run Tests
```bash
# Run basic test
make sim

# Run with specific test and seed
make sim TEST=fifo_burst_test SEED=42

# Run with GUI
make gui TEST=fifo_random_test

# Run all tests
make test_all

# Run regression
make regression
```

## Available Tests

| Test Name | Description |
|-----------|-------------|
| `fifo_random_test` | Random read/write operations (default) |
| `fifo_fill_empty_test` | Systematic fill and empty operations |
| `fifo_burst_test` | Simultaneous read/write burst operations |
| `fifo_corner_test` | Corner case and edge condition testing |
| `fifo_stress_test` | High-intensity stress testing |

## Configuration

### DUT Parameters
The VIP supports the following FIFO configurations:

```systemverilog
class fifo_config extends uvm_object;
    // DUT Parameters - Modify these to match your FIFO
    int DEPTH = 12;        // FIFO depth
    int DATA_WIDTH = 8;    // Data width in bits
    bit ASYNC = 1;         // Asynchronous operation
    bit RD_BUFFER = 1;     // Read buffering enabled
    
    // Clock Configuration - Update for your system
    int WR_CLK_PERIOD = 20;  // Write clock period (ns)
    int RD_CLK_PERIOD = 32;  // Read clock period (ns)
    
    // Environment Configuration - Control VIP behavior
    bit has_wr_agent = 1;      // Enable write agent
    bit has_rd_agent = 1;      // Enable read agent  
    bit has_scoreboard = 1;    // Enable scoreboard checking
    bit has_coverage = 1;      // Enable coverage collection
endclass
```

### Critical Environment Variables to Modify

Before using the VIP, you **MUST** update these key variables in your test environment:

#### 1. **UVM_HOME Environment Variable**
```bash
# Set path to your UVM installation
export UVM_HOME=/tools/uvm/uvm-1.2
```

#### 2. **DUT-Specific Configuration**
Update `fifo_config` in your test's `build_phase()`:

```systemverilog
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    cfg = fifo_config::type_id::create("cfg");
    
    // *** MODIFY THESE FOR YOUR FIFO DESIGN ***
    cfg.DEPTH = 16;           // Change to your FIFO depth
    cfg.DATA_WIDTH = 32;      // Change to your data width
    cfg.ASYNC = 1;            // 1 for async, 0 for sync
    cfg.RD_BUFFER = 0;        // 1 for buffered read, 0 for combinational
    cfg.WR_CLK_PERIOD = 10;   // Write clock period in ns
    cfg.RD_CLK_PERIOD = 15;   // Read clock period in ns
    
    uvm_config_db#(fifo_config)::set(this, "*", "cfg", cfg);
    env = fifo_env::type_id::create("env", this);
endfunction
```

#### 3. **Interface Signal Mapping**
In `fifo_tb_top.sv`, update the DUT instantiation to match your FIFO ports:

```systemverilog
// *** MODIFY DUT INSTANTIATION FOR YOUR DESIGN ***
fifo #(
    .DEPTH(cfg.DEPTH),              // Use your parameter names
    .DATA_WIDTH(cfg.DATA_WIDTH),    // Match your FIFO parameters
    .ASYNC(cfg.ASYNC),
    .RD_BUFFER(cfg.RD_BUFFER)
) DUT (
    // *** MAP THESE TO YOUR FIFO PORT NAMES ***
    .rd_clk(rd_clk),                    // Your read clock port
    .wr_clk(wr_clk),                    // Your write clock port  
    .rst(rst),                          // Your reset port
    .data_wr(fifo_if.data_wr[7:0]),    // Your write data port
    .wr_en(fifo_if.wr_en),             // Your write enable port
    .fifo_full(fifo_if.fifo_full),     // Your full flag port
    .data_rd(fifo_if.data_rd[7:0]),    // Your read data port
    .rd_en(fifo_if.rd_en),             // Your read enable port
    .fifo_empty(fifo_if.fifo_empty)    // Your empty flag port
);
```

## Agent Instantiation Guide

### How to Instantiate and Configure the FIFO Agent

The FIFO VIP uses a standard UVM agent architecture. Here's how to instantiate and configure it:

#### 1. **Basic Agent Instantiation**

```systemverilog
class my_fifo_test extends uvm_test;
    `uvm_component_utils(my_fifo_test)
    
    fifo_env env;           // Environment contains the agent
    fifo_config cfg;        // Configuration object
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create and configure the config object
        cfg = fifo_config::type_id::create("cfg");
        cfg.DEPTH = 16;                    // Your FIFO depth
        cfg.DATA_WIDTH = 8;                // Your data width
        cfg.ASYNC = 1;                     // Async/sync mode
        cfg.RD_BUFFER = 1;                 // Read buffering
        
        // Set config in database
        uvm_config_db#(fifo_config)::set(this, "*", "cfg", cfg);
        uvm_config_db#(virtual fifo_interface)::set(this, "*", "vif", tb_top.fifo_if);
        
        // Create environment (which creates the agent)
        env = fifo_env::type_id::create("env", this);
    endfunction
endclass
```

#### 2. **Direct Agent Instantiation (Advanced)**

If you need to instantiate the agent directly:

```systemverilog
class my_custom_env extends uvm_env;
    `uvm_component_utils(my_custom_env)
    
    fifo_agent agent;
    fifo_config cfg;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(fifo_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "Configuration not found")
        end
        
        // Set agent configuration
        uvm_config_db#(fifo_config)::set(this, "agent", "cfg", cfg);
        uvm_config_db#(virtual fifo_interface)::set(this, "agent", "vif", vif);
        
        // Create agent
        agent = fifo_agent::type_id::create("agent", this);
        
        // Configure agent mode
        agent.set_is_active(UVM_ACTIVE);  // or UVM_PASSIVE for monitor only
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect agent's analysis port to your subscribers
        // agent.ap.connect(your_subscriber.analysis_export);
    endfunction
endclass
```

#### 3. **Multi-Agent Configuration**

For complex scenarios with multiple agents:

```systemverilog
class multi_fifo_env extends uvm_env;
    `uvm_component_utils(multi_fifo_env)
    
    fifo_agent wr_agent;    // Write-only agent
    fifo_agent rd_agent;    // Read-only agent
    fifo_agent mon_agent;   // Monitor-only agent
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Configure write agent
        uvm_config_db#(fifo_config)::set(this, "wr_agent", "cfg", cfg);
        uvm_config_db#(virtual fifo_interface)::set(this, "wr_agent", "vif", vif);
        wr_agent = fifo_agent::type_id::create("wr_agent", this);
        wr_agent.set_is_active(UVM_ACTIVE);
        
        // Configure read agent  
        uvm_config_db#(fifo_config)::set(this, "rd_agent", "cfg", cfg);
        uvm_config_db#(virtual fifo_interface)::set(this, "rd_agent", "vif", vif);
        rd_agent = fifo_agent::type_id::create("rd_agent", this);
        rd_agent.set_is_active(UVM_ACTIVE);
        
        // Configure monitor-only agent
        uvm_config_db#(fifo_config)::set(this, "mon_agent", "cfg", cfg);
        uvm_config_db#(virtual fifo_interface)::set(this, "mon_agent", "vif", vif);
        mon_agent = fifo_agent::type_id::create("mon_agent", this);
        mon_agent.set_is_active(UVM_PASSIVE);  // Monitor only
    endfunction
endclass
```

#### 4. **Agent Configuration Variables**

Key configuration variables you should modify:

```systemverilog
// In your test's build_phase()
cfg = fifo_config::type_id::create("cfg");

// *** CRITICAL: Modify these for your FIFO ***
cfg.DEPTH = 32;                    // Must match your FIFO depth
cfg.DATA_WIDTH = 16;               // Must match your data width
cfg.ASYNC = 1;                     // 1=async clocks, 0=sync clocks
cfg.RD_BUFFER = 0;                 // 1=buffered read, 0=combinational read

// Clock periods (affects driver timing)
cfg.WR_CLK_PERIOD = 8;             // Write clock period in ns
cfg.RD_CLK_PERIOD = 12;            // Read clock period in ns

// VIP behavior control
cfg.has_wr_agent = 1;              // Enable write operations
cfg.has_rd_agent = 1;              // Enable read operations
cfg.has_scoreboard = 1;            // Enable checking
cfg.has_coverage = 1;              // Enable coverage collection

// Apply configuration
uvm_config_db#(fifo_config)::set(this, "*", "cfg", cfg);
```

## Verification Methodology

### 1. **Layered Architecture**
- **Transaction Layer**: Defines FIFO operations (read/write/idle)
- **Agent Layer**: Contains driver, monitor, and sequencer
- **Environment Layer**: Integrates agents with scoreboard and coverage
- **Test Layer**: Implements specific test scenarios

### 2. **Self-Checking Mechanism**
- **Reference Model**: Built-in queue-based reference model
- **Automatic Comparison**: Real-time comparison of expected vs actual results
- **Error Reporting**: Detailed error messages with timestamps

### 3. **Coverage Metrics**
- **Operation Coverage**: All FIFO operations (read, write, idle)
- **Data Coverage**: Corner data values and random data patterns
- **State Coverage**: Full, empty, and normal operation states
- **Cross Coverage**: Operation combinations and state transitions

### Adapting to Different FIFO Designs

1. **Modify Interface**: Update `fifo_interface` to match your FIFO ports
2. **Adjust Parameters**: Modify `fifo_config` for your specific requirements
3. **Update Monitor**: Adapt monitoring logic for your FIFO's behavior
4. **Customize Sequences**: Create application-specific test sequences

## Troubleshooting

### Common Issues

## License

This FIFO UVM VIP is provided as an example verification environment. Adapt and modify according to your specific requirements.

---

**Happy Verifying! 🚀**

For questions or support, please refer to the UVM User Guide or SystemVerilog documentation.
