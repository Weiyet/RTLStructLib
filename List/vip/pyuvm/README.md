# List pyUVM VIP (Verification IP) User Guide

This legacy VIP currently fails during Python imports. Its Makefile uses
`../../../Utils/vip/pyuvm/Makefile`; use `../../tb/` for standalone RTL verification.

## 📁 Directory Structure

```
pyuvm/
├── README.md                                  [User guide and documentation]
├── common/                                    [Core VIP source files]
│   ├── __init__.py
│   ├── list_vip_types.py                     [Enums and types]
│   ├── list_vip_config.py                    [Configuration class]
│   └── list_vip_seq_item.py                  [Transaction definitions]
├── agent/                                     [Agent layer components]
│   ├── __init__.py
│   ├── list_vip_driver.py                    [Driver implementation]
│   ├── list_vip_monitor.py                   [Monitor implementation]
│   ├── list_vip_sequencer.py                 [Sequencer]
│   └── list_vip_agent.py                     [Agent wrapper]
├── env/                                       [Environment layer]
│   ├── __init__.py
│   ├── list_vip_env.py                       [Environment]
│   └── list_vip_scoreboard.py                [Checking components]
├── sequences/                                 [Test sequences]
│   ├── __init__.py
│   ├── list_vip_base_seq.py                  [Base sequence]
│   ├── list_vip_insert_seq.py                [Insert sequences]
│   ├── list_vip_read_seq.py                  [Read sequences]
│   ├── list_vip_delete_seq.py                [Delete sequences]
│   ├── list_vip_find_seq.py                  [Find sequences]
│   ├── list_vip_sort_seq.py                  [Sort sequences]
│   └── list_vip_sum_seq.py                   [Sum sequences]
├── tests/                                     [Test classes]
│   ├── __init__.py
│   ├── list_vip_base_test.py                 [Base test]
│   └── list_vip_simple_test.py               [Simple & random tests]
└── tb_list.py                                 [Testbench top with cocotb]
```

## 🚀 Quick Start

**Step 1:** Install dependencies
```bash
pip install pyuvm cocotb
```

**Step 2:** Update configuration in your test:
```python
from common.list_vip_config import ListVipConfig

# Create config
cfg = ListVipConfig("cfg")
cfg.DATA_WIDTH = 8
cfg.LENGTH = 8
cfg.SUM_METHOD = 0
ConfigDB().set(None, "*", "list_vip_cfg", cfg)
```

**Step 3:** Create and run test:
```python
from tests.list_vip_simple_test import SimpleTest

# In your cocotb test
await uvm_root().run_test("SimpleTest")
```

## 🧪 Running Tests

### Quick Start

```bash
cd List/vip/pyuvm

# Run all tests with Icarus Verilog
make

# Enable waveforms
make WAVES=1

# Run specific test
make TESTCASE=list_simple_test

# View waveforms
gtkwave sim_build/list.fst

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
make DATA_WIDTH=8 LENGTH=8 SUM_METHOD=0
```

**Note:** Run `make clean` before changing parameters!

## 📋 List Operations

The VIP supports 9 operation types:

| Operation | Description | Op Code |
|-----------|-------------|---------|
| **READ** | Read data at index | 0b000 |
| **INSERT** | Insert data at index | 0b001 |
| **FIND_ALL** | Find all indices of value | 0b010 |
| **FIND_1ST** | Find first index of value | 0b011 |
| **SUM** | Sum all elements | 0b100 |
| **SORT_ASC** | Sort ascending | 0b101 |
| **SORT_DES** | Sort descending | 0b110 |
| **DELETE** | Delete element at index | 0b111 |
| **IDLE** | No operation | N/A |

## 🚀 Available Sequences

**Insert Sequence:**
```python
from sequences.list_vip_insert_seq import ListVipInsertSeq

insert_seq = ListVipInsertSeq("insert_seq")
insert_seq.num_inserts = 5
insert_seq.random_index = False  # Append at end
await insert_seq.start(env.get_sequencer())
```

**Read Sequence:**
```python
from sequences.list_vip_read_seq import ListVipReadSeq

read_seq = ListVipReadSeq("read_seq")
read_seq.num_reads = 5
await read_seq.start(env.get_sequencer())
```

**Delete Sequence:**
```python
from sequences.list_vip_delete_seq import ListVipDeleteSeq

delete_seq = ListVipDeleteSeq("delete_seq")
delete_seq.num_deletes = 3
await delete_seq.start(env.get_sequencer())
```

**Find Sequence:**
```python
from sequences.list_vip_find_seq import ListVipFindSeq

find_seq = ListVipFindSeq("find_seq")
find_seq.num_finds = 3
find_seq.find_all = False  # Use FIND_1ST
await find_seq.start(env.get_sequencer())
```

**Sort Sequence:**
```python
from sequences.list_vip_sort_seq import ListVipSortSeq

sort_seq = ListVipSortSeq("sort_seq")
sort_seq.ascending = True  # Sort ascending
await sort_seq.start(env.get_sequencer())
```

**Sum Sequence:**
```python
from sequences.list_vip_sum_seq import ListVipSumSeq

sum_seq = ListVipSumSeq("sum_seq")
await sum_seq.start(env.get_sequencer())
```

## ✅ Self-Checking Features

The scoreboard automatically verifies:
- ✅ Data integrity (read returns correct values)
- ✅ Insert operation (list grows correctly)
- ✅ Delete operation (list shrinks correctly)
- ✅ Find operations (correct index returned)
- ✅ Sum operation (correct sum calculated)
- ✅ Sort operations (model updated correctly)
- ✅ List length tracking
- ✅ Error conditions (out of bounds, full list, empty list)

## 🔧 Key Features

1. **Rich Operation Set**: Support for READ, INSERT, DELETE, FIND, SORT, SUM
2. **Python-Based**: Easy to extend and modify
3. **Cocotb Integration**: Works with cocotb simulator interface
4. **Self-Checking**: Automatic scoreboard verification
5. **Configurable**: Supports different List parameters
6. **Reference Model**: Python list tracks expected behavior

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
self.dut.op_en.value = 1  # Make sure 'op_en' matches RTL port name
```

### Issue: Cocotb not finding testbench
**Solution:** Ensure MODULE variable in Makefile points to correct Python file:
```makefile
MODULE = tb_list  # Without .py extension
```

## 📚 Example Test

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from pyuvm import *
from tests.list_vip_simple_test import SimpleTest

@cocotb.test()
async def my_list_test(dut):
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
  └── Environment (ListVipEnv)
      ├── Agent (ListVipAgent)
      │   ├── Driver (ListVipDriver)
      │   ├── Monitor (ListVipMonitor)
      │   └── Sequencer (ListVipSequencer)
      └── Scoreboard (ListVipScoreboard)
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
