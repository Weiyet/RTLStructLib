# Singly Linked List pyUVM VIP (Verification IP) User Guide

This legacy VIP currently fails during Python imports. Its Makefile uses
`../../../Utils/vip/pyuvm/Makefile`; use `../../tb/` for standalone RTL verification.

## 📁 Directory Structure

```
pyuvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── __init__.py
│   ├── sll_vip_types.py                      [Enums and types]
│   ├── sll_vip_config.py                     [Configuration class]
│   └── sll_vip_seq_item.py                   [Transaction definitions]
├── agent/                                     [Agent layer components]
│   ├── __init__.py
│   ├── sll_vip_driver.py                     [Driver implementation]
│   ├── sll_vip_monitor.py                    [Monitor implementation]
│   ├── sll_vip_sequencer.py                  [Sequencer]
│   └── sll_vip_agent.py                      [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── __init__.py
│   ├── sll_vip_env.py                        [Environment]
│   └── sll_vip_scoreboard.py                 [Checking components]
├── sequences/                                 [Test sequences]
│   ├── __init__.py
│   ├── sll_vip_base_seq.py                   [Base sequence]
│   ├── sll_vip_insert_seq.py                 [Insert sequences]
│   ├── sll_vip_read_seq.py                   [Read sequences]
│   └── sll_vip_delete_seq.py                 [Delete sequences]
├── tests/                                     [Test classes]
│   ├── __init__.py
│   ├── sll_vip_base_test.py                  [Base test]
│   └── sll_vip_simple_test.py                [Simple & random tests]
└── tb_sll.py                                  [Testbench top with cocotb]
```

## 🚀 Quick Start

**Step 1:** Install dependencies
```bash
pip install pyuvm cocotb
```

**Step 2:** Update configuration in your test:
```python
from common.sll_vip_config import SllVipConfig

# Create config
cfg = SllVipConfig("cfg")
cfg.DATA_WIDTH = 8
cfg.MAX_NODE = 8
ConfigDB().set(None, "*", "sll_vip_cfg", cfg)
```

**Step 3:** Create and run test:
```python
from tests.sll_vip_simple_test import SimpleTest

# In your cocotb test
await uvm_root().run_test("SimpleTest")
```

## 🧪 Running Tests

### Quick Start

```bash
cd Singly_Linked_List/vip/pyuvm

# Run all tests with Icarus Verilog
make

# Enable waveforms
make WAVES=1

# Run specific test
make TESTCASE=sll_simple_test

# View waveforms
gtkwave sim_build/singly_linked_list.fst

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
make DATA_WIDTH=8 MAX_NODE=8
```

**Note:** Run `make clean` before changing parameters!

## 📋 Singly Linked List Operations

The VIP supports 7 operation types:

| Operation | Description | Op Code |
|-----------|-------------|---------|
| **READ_ADDR** | Read data at address | 0 |
| **INSERT_AT_ADDR** | Insert data at address | 1 |
| **DELETE_VALUE** | Delete by value | 2 |
| **DELETE_AT_ADDR** | Delete at address | 3 |
| **IDLE** | No operation | 4 |
| **INSERT_AT_INDEX** | Insert at index | 5 |
| **DELETE_AT_INDEX** | Delete at index | 7 |

## 🚀 Available Sequences

**Insert Sequence:**
```python
from sequences.sll_vip_insert_seq import SllVipInsertSeq

insert_seq = SllVipInsertSeq("insert_seq")
insert_seq.num_inserts = 5
insert_seq.use_index = False  # Use INSERT_AT_ADDR
await insert_seq.start(env.get_sequencer())
```

**Read Sequence:**
```python
from sequences.sll_vip_read_seq import SllVipReadSeq

read_seq = SllVipReadSeq("read_seq")
read_seq.num_reads = 5
await read_seq.start(env.get_sequencer())
```

**Delete Sequence:**
```python
from sequences.sll_vip_delete_seq import SllVipDeleteSeq

delete_seq = SllVipDeleteSeq("delete_seq")
delete_seq.num_deletes = 3
delete_seq.delete_mode = "addr"  # "addr", "index", or "value"
await delete_seq.start(env.get_sequencer())
```

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity (read returns correct values)
- ✅ Insert operations (at address or index)
- ✅ Delete operations (by value, address, or index)
- ✅ List length tracking
- ✅ Head and tail pointer management
- ✅ Next pointer correctness (singly linked)
- ✅ Error conditions (invalid address, empty list, full list)

## 🔧 Key Features

1. **Singly Linked List**: Forward pointers only (no prev pointer)
2. **Multiple Insert/Delete Modes**: By address, index, or value
3. **Python-Based**: Easy to extend and modify
4. **Cocotb Integration**: Works with cocotb simulator interface
5. **Self-Checking**: Automatic scoreboard verification
6. **Configurable**: Supports different parameters
7. **Reference Model**: Python lists track expected behavior

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
self.dut.op_start.value = 1  # Make sure 'op_start' matches RTL port name
```

### Issue: Cocotb not finding testbench
**Solution:** Ensure MODULE variable in Makefile points to correct Python file:
```makefile
MODULE = tb_sll  # Without .py extension
```

## 📚 Example Test

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from pyuvm import *
from tests.sll_vip_simple_test import SimpleTest

@cocotb.test()
async def my_sll_test(dut):
    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

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
  └── Environment (SllVipEnv)
      ├── Agent (SllVipAgent)
      │   ├── Driver (SllVipDriver)
      │   ├── Monitor (SllVipMonitor)
      │   └── Sequencer (SllVipSequencer)
      └── Scoreboard (SllVipScoreboard)
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
