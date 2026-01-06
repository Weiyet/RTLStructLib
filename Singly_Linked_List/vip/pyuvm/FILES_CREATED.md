# Singly Linked List pyUVM VIP - Files Created

## Complete File List (24 files total)

### 📂 Root Directory (6 files)
- ✅ `__init__.py` - Root package initialization
- ✅ `Makefile` - Build and run system
- ✅ `tb_sll.py` - Main testbench with cocotb tests
- ✅ `README.md` - Complete documentation
- ✅ `QUICKSTART.md` - Quick start guide
- ✅ `FILES_CREATED.md` - This file

### 📂 common/ (4 files)
- ✅ `__init__.py` - Package initialization
- ✅ `sll_vip_types.py` - Enums (SllOp)
- ✅ `sll_vip_config.py` - Configuration class
- ✅ `sll_vip_seq_item.py` - Transaction item with randomization

### 📂 agent/ (5 files)
- ✅ `__init__.py` - Package initialization
- ✅ `sll_vip_sequencer.py` - Sequencer component
- ✅ `sll_vip_driver.py` - Driver with async/await (all operations)
- ✅ `sll_vip_monitor.py` - Monitor with analysis port
- ✅ `sll_vip_agent.py` - Agent wrapper

### 📂 env/ (3 files)
- ✅ `__init__.py` - Package initialization
- ✅ `sll_vip_scoreboard.py` - Self-checking scoreboard with list model
- ✅ `sll_vip_env.py` - Environment connecting agent and scoreboard

### 📂 sequences/ (4 files)
- ✅ `__init__.py` - Package initialization
- ✅ `sll_vip_base_seq.py` - Base sequence class
- ✅ `sll_vip_insert_seq.py` - Insert sequence (at addr or index)
- ✅ `sll_vip_read_seq.py` - Read sequence
- ✅ `sll_vip_delete_seq.py` - Delete sequence (by value, addr, or index)

### 📂 tests/ (3 files)
- ✅ `__init__.py` - Package initialization
- ✅ `sll_vip_base_test.py` - Base test class with config
- ✅ `sll_vip_simple_test.py` - SimpleTest and RandomTest classes

## How to Use

### 1. Run Tests
```bash
cd Singly_Linked_List/vip/pyuvm
make                    # Run all tests
make WAVES=0            # Disable waveforms
```

### 2. View Waveforms
```bash
gtkwave singly_linked_list.vcd
```

### 3. Modify Tests
Edit files in `tests/` directory:
- `sll_vip_simple_test.py` - Add new test classes
- Inherit from `BaseTest` class

### 4. Add Sequences
Create new files in `sequences/` directory:
- Inherit from `SllVipBaseSeq`
- Implement `async def body()`

## Comparison with SystemVerilog UVM

| Item | SV UVM | pyUVM |
|------|--------|-------|
| **Total Files** | 16 | 24 (includes __init__.py) |
| **Config** | sll_vip_config.sv | sll_vip_config.py |
| **Driver** | sll_vip_driver.sv | sll_vip_driver.py |
| **Monitor** | sll_vip_monitor.sv | sll_vip_monitor.py |
| **Agent** | sll_vip_agent.sv | sll_vip_agent.py |
| **Env** | sll_vip_env.sv | sll_vip_env.py |
| **Scoreboard** | sll_vip_scoreboard.sv | sll_vip_scoreboard.py |
| **Sequences** | .sv files (3 sequences) | .py files (3 sequences) |
| **Tests** | .sv files | .py files |
| **Build System** | None (part of tb) | Makefile |

## Key Differences from SV UVM

1. **Python Modules**: Each directory has `__init__.py` for Python imports
2. **Makefile**: Standalone Makefile for building and running
3. **Async/Await**: Uses Python coroutines instead of tasks
4. **No Macros**: Clean Python syntax vs SV macros
5. **Cocotb Integration**: Direct DUT signal access via cocotb
6. **Singly Linked**: Forward pointers only (no prev pointer)

## Supported Operations

The pyUVM VIP supports all Singly Linked List operations:

| Operation | Sequence | Description |
|-----------|----------|-------------|
| READ_ADDR | SllVipReadSeq | Read data at address |
| INSERT_AT_ADDR | SllVipInsertSeq | Insert data at address |
| INSERT_AT_INDEX | SllVipInsertSeq | Insert data at index |
| DELETE_VALUE | SllVipDeleteSeq | Delete by value |
| DELETE_AT_ADDR | SllVipDeleteSeq | Delete at address |
| DELETE_AT_INDEX | SllVipDeleteSeq | Delete at index |

## Dependencies

### Required
- Python 3.7+
- pyuvm (pip install pyuvm)
- cocotb (pip install cocotb)

### Simulator
- Icarus Verilog (free, recommended)

## Next Steps

1. **Read QUICKSTART.md** - Get running in 5 minutes
2. **Read README.md** - Full documentation
3. **Compare with SV UVM** - See ../uvm/ directory
4. **Modify Tests** - Add your own test scenarios

## Architecture Match

The pyUVM VIP matches the SystemVerilog UVM VIP:

```
SV UVM                          pyUVM
------                          -----
sll_vip_pkg.sv           ←→     __init__.py (imports all)
sll_vip_config.sv        ←→     sll_vip_config.py
sll_vip_seq_item.sv      ←→     sll_vip_seq_item.py
sll_vip_driver.sv        ←→     sll_vip_driver.py
sll_vip_monitor.sv       ←→     sll_vip_monitor.py
sll_vip_sequencer.sv     ←→     sll_vip_sequencer.py
sll_vip_agent.sv         ←→     sll_vip_agent.py
sll_vip_env.sv           ←→     sll_vip_env.py
sll_vip_scoreboard.sv    ←→     sll_vip_scoreboard.py
sll_vip_*_seq.sv         ←→     sll_vip_*_seq.py
sll_vip_*_test.sv        ←→     sll_vip_*_test.py
tb_top.sv                ←→     tb_sll.py + Makefile
```

**Happy Verifying with pyUVM! 🐍🚀**
