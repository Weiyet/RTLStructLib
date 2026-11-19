# FIFO (Queue) pyUVM VIP (Verification IP) User Guide

This legacy VIP currently fails during Python imports. Its Makefile uses
`../../../Utils/vip/pyuvm/Makefile`; use `../../tb/` for standalone RTL verification.

## 📁 Directory Structure

```
pyuvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── __init__.py
│   ├── fifo_vip_types.py                     [Enums and types]
│   ├── fifo_vip_config.py                    [Configuration class]
│   └── fifo_vip_seq_item.py                  [Transaction definitions]
├── agent/                                     [Agent layer components]
│   ├── __init__.py
│   ├── fifo_vip_driver.py                    [Driver implementation]
│   ├── fifo_vip_monitor.py                   [Monitor implementation]
│   ├── fifo_vip_sequencer.py                 [Sequencer]
│   └── fifo_vip_agent.py                     [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── __init__.py
│   ├── fifo_vip_env.py                       [Environment]
│   └── fifo_vip_scoreboard.py                [Checking components]
├── sequences/                                 [Test sequences]
│   ├── __init__.py
│   ├── fifo_vip_base_seq.py                  [Base sequence]
│   ├── fifo_vip_write_req_seq.py             [Write sequences]
│   └── fifo_vip_read_req_seq.py              [Read sequences]
├── tests/                                     [Test classes]
│   ├── __init__.py
│   ├── fifo_vip_base_test.py                 [Base test]
│   └── fifo_vip_simple_test.py               [Simple & random tests]
└── tb_fifo.py                                 [Testbench top with cocotb]
```

## 🚀 Quick Start

**Step 1:** Install dependencies
```bash
pip install pyuvm cocotb
```

**Step 2:** Update configuration in your test:
```python
from common.fifo_vip_config import FifoVipConfig

# Create config
cfg = FifoVipConfig("cfg")
cfg.DEPTH = 16
cfg.DATA_WIDTH = 8
cfg.ASYNC = 1
cfg.RD_BUFFER = 1
ConfigDB().set(None, "*", "fifo_vip_cfg", cfg)
```

**Step 3:** Create and run test:
```python
from tests.fifo_vip_simple_test import SimpleTest

# In your cocotb test
await uvm_root().run_test("SimpleTest")
```

## 🚀 Available Sequences

**Write Sequence:**
```python
from sequences.fifo_vip_write_req_seq import FifoVipWriteReqSeq

wr_seq = FifoVipWriteReqSeq("wr_seq")
wr_seq.num_writes = 10
await wr_seq.start(env.get_wr_sequencer())
```

**Read Sequence:**
```python
from sequences.fifo_vip_read_req_seq import FifoVipReadReqSeq

rd_seq = FifoVipReadReqSeq("rd_seq")
rd_seq.num_reads = 10
await rd_seq.start(env.get_rd_sequencer())
```

## 🧪 Running Tests

### Quick Start 

```bash
cd FIFO/vip/pyuvm

# Run all tests with Icarus Verilog
make

# Enable waveforms
make WAVES=1

# Run specific test
make TESTCASE=fifo_simple_test

# View waveforms
gtkwave sim_build/fifo.fst

# Clean build files
make clean
```

### Available Make Targets

| Command | Description |
|---------|-------------|
| `make` | Run all tests with Icarus Verilog, waves disabled by default |
| `make WAVES=1` | Enable waveform generation |
| `make TESTCASE=<name>` | Run specific test only |
| `make clean` | Clean build files |
| `make help` | Show help message |

### DUT Parameters

Override the local Makefile defaults on the command line:
```bash
make DEPTH=16 DATA_WIDTH=8 ASYNC=1 RD_BUFFER=1
```

**Note:** Run `make clean` before changing parameters!

## 📋 FIFO Operations

The VIP supports 3 operation types:

| Operation | Description | Agent Type |
|-----------|-------------|------------|
| **WRITE** | Write data to FIFO | Write Agent |
| **READ** | Read data from FIFO | Read Agent |
| **IDLE** | No operation | Either |

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity through FIFO (FIFO order)
- ✅ Write when full behavior
- ✅ Read when empty behavior
- ✅ FIFO flag correctness (full/empty)
- ✅ Transaction success/failure

## 🔧 Key Features

1. **Dual-Agent Architecture**: Separate write and read agents for async FIFO
2. **Python-Based**: Easy to extend and modify
3. **Cocotb Integration**: Works with cocotb simulator interface
4. **Self-Checking**: Automatic scoreboard verification
5. **Configurable**: Supports different FIFO parameters

## 📊 Comparison: SystemVerilog UVM vs pyUVM

| Aspect | SV UVM | pyUVM |
|--------|--------|-------|
| **Language** | SystemVerilog | Python |
| **Syntax** | Complex macros | Clean Python |
| **Debug** | Waveforms + logs | Print statements + logs |
| **Extensibility** | Limited | High (Python ecosystem) |
| **Learning Curve** | Steep | Moderate |
| **Performance** | Faster | Slightly slower |

## 🚨 Common Issues & Solutions

### Issue: Import errors
**Solution:** Make sure all `__init__.py` files are present and pyUVM is installed:
```bash
pip install pyuvm
```

### Issue: DUT signals not found
**Solution:** Check that signal names match your RTL:
```python
# In driver.py
self.dut.wr_en.value = 1  # Make sure 'wr_en' matches RTL port name
```

### Issue: Cocotb not finding testbench
**Solution:** Ensure MODULE variable in Makefile points to correct Python file:
```makefile
MODULE = tb_fifo  # Without .py extension
```

## 📚 Example Test

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from pyuvm import *
from tests.fifo_vip_simple_test import SimpleTest

@cocotb.test()
async def my_fifo_test(dut):
    # Start clocks
    cocotb.start_soon(Clock(dut.wr_clk, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.rd_clk, 10, units="ns").start())

    # Reset
    dut.rst.value = 1
    await Timer(50, units="ns")
    dut.rst.value = 0
    await Timer(10, units="ns")

    # Run UVM test
    await uvm_root().run_test("SimpleTest")
```

## 🎯 Key Characteristics

- **Pythonic UVM**: UVM methodology in Python
- **Async/Await**: Uses Python coroutines for concurrency
- **Cocotb-Based**: Leverages cocotb for RTL interaction
- **Modular**: Easy to reuse components
- **Extensible**: Add new sequences and tests easily

## 📈 Architecture

```
Test (SimpleTest)
  └── Environment (FifoVipEnv)
      ├── Write Agent (FifoVipAgent)
      │   ├── Driver (FifoVipDriver)
      │   ├── Monitor (FifoVipMonitor)
      │   └── Sequencer (FifoVipSequencer)
      ├── Read Agent (FifoVipAgent)
      │   ├── Driver (FifoVipDriver)
      │   ├── Monitor (FifoVipMonitor)
      │   └── Sequencer (FifoVipSequencer)
      └── Scoreboard (FifoVipScoreboard)
```

## 🔍 Python vs SystemVerilog UVM Mapping

| SystemVerilog | Python/pyUVM |
|---------------|--------------|
| `uvm_config_db::set()` | `ConfigDB().set()` |
| `uvm_config_db::get()` | `ConfigDB().get()` |
| `` `uvm_component_utils()`` | Inherit from `uvm_component` |
| `task run_phase()` | `async def run_phase()` |
| `@(posedge clk)` | `await RisingEdge(dut.clk)` |
| `#100ns` | `await Timer(100, units="ns")` |
| `start_item()` | `await self.start_item()` |

## 💡 Advantages of pyUVM

1. **Easier Debugging**: Python print() and pdb debugger
2. **Rich Ecosystem**: Use NumPy, Pandas for analysis
3. **Rapid Development**: Faster iteration cycle
4. **Better Readability**: Clean Python syntax
5. **Cross-Platform**: Works on Linux, Windows, Mac

## 🚧 Limitations

1. **Performance**: Slightly slower than SystemVerilog
2. **Tool Support**: Fewer commercial tools support Python UVM
3. **Community**: Smaller than SystemVerilog UVM community
4. **Coverage**: Functional coverage less mature

## 🔗 Resources

- pyUVM Documentation: https://pyuvm.github.io/pyuvm/
- Cocotb Documentation: https://docs.cocotb.org/
- SystemVerilog UVM Reference: https://www.accellera.org/downloads/standards/uvm

**Happy Verifying with Python! 🐍🚀**

*This pyUVM VIP demonstrates modern verification using Python and UVM methodology.*
