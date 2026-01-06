# Singly Linked List pyUVM VIP - Quick Start Guide

## 🚀 Getting Started

### 1. Install Dependencies

```bash
# Install Python packages
pip install pyuvm cocotb

# For Icarus Verilog (recommended for beginners)
# Windows: Download from http://bleyer.org/icarus/
# Linux: sudo apt-get install iverilog
# Mac: brew install icarus-verilog
```

### 2. Run Your First Test

```bash
cd Singly_Linked_List/vip/pyuvm

# Run with Icarus Verilog
make

# Run with waveforms disabled (faster)
make WAVES=0

# Run specific test
make TESTCASE=sll_simple_test

# Clean build files
make clean
```

### 3. View Waveforms

After running with `WAVES=1` (default):
```bash
# View with GTKWave
gtkwave singly_linked_list.vcd

# Or on Windows
gtkwave.exe singly_linked_list.vcd
```

## 📂 File Structure Quick Reference

```
pyuvm/
├── Makefile                    ← Run "make" here
├── tb_sll.py                   ← Main testbench
├── common/                     ← Config & transaction types
├── agent/                      ← Driver, monitor, sequencer
├── env/                        ← Environment & scoreboard
├── sequences/                  ← Test sequences
└── tests/                      ← Test classes
```

## 🧪 Available Tests

The testbench includes 2 pre-built tests:

1. **sll_simple_test** - Insert, read, delete operations
2. **sll_random_test** - Random mixed operations with different delete modes

## 🔧 Customize DUT Parameters

Edit the `Makefile` to change Singly Linked List parameters:

```makefile
COMPILE_ARGS = -Psingly_linked_list.DATA_WIDTH=8     # Change data width
COMPILE_ARGS += -Psingly_linked_list.MAX_NODE=8      # Change max nodes
```

Then run:
```bash
make clean  # Must clean first!
make
```

## 🐛 Debugging

### Enable Verbose Logging

In `tb_sll.py`, add:
```python
cocotb.log.setLevel(cocotb.logging.DEBUG)
```

### Python Debugger

Add breakpoint in Python code:
```python
import pdb; pdb.set_trace()
```

### Check Simulator Output

```bash
# Output is in terminal and sim_build/
cat sim_build/sim.log
```

## 📊 Expected Output

```
============================================================
Starting Singly Linked List Simple Test (pyUVM)
============================================================
DUT Parameters: DATA_WIDTH=8, MAX_NODE=8
DUT initialization complete
Test: Inserting 5 nodes
Test: Reading 5 nodes
Test: Deleting 2 nodes
Test: Reading after delete
============================================================
Singly Linked List Simple Test Complete
============================================================
```

## 🆚 Comparison with SystemVerilog UVM

| Task | SystemVerilog UVM | pyUVM (This VIP) |
|------|-------------------|------------------|
| **Run test** | `vsim +UVM_TESTNAME=simple_test` | `make` |
| **Change params** | Edit tb_top.sv | Edit Makefile |
| **View waves** | Open in simulator | `gtkwave singly_linked_list.vcd` |
| **Debug** | $display + waveforms | print() + pdb |
| **Add test** | Create .sv file | Create .py function |

## ❓ Troubleshooting

### Issue: "No module named 'pyuvm'"
```bash
pip install pyuvm
```

### Issue: "No module named 'cocotb'"
```bash
pip install cocotb
```

### Issue: "make: cocotb-config: Command not found"
```bash
# Check installation
which cocotb-config
python -m cocotb --help

# Reinstall if needed
pip uninstall cocotb
pip install cocotb
```

### Issue: Waveform file not generated
```bash
# Make sure WAVES=1 (default)
make clean
make WAVES=1
```

### Issue: Simulator not found
```bash
# Install Icarus Verilog
# Windows: http://bleyer.org/icarus/
# Linux: sudo apt-get install iverilog
# Mac: brew install icarus-verilog
```

## 📚 Next Steps

1. **Read the full README.md** - Comprehensive documentation
2. **Study the code** - Start with `tb_sll.py`, then explore agent/
3. **Modify tests** - Edit `tests/sll_vip_simple_test.py`
4. **Add sequences** - Create new sequences in `sequences/`
5. **Compare with SV UVM** - See `../uvm/` for SystemVerilog version

## 🔗 Useful Links

- **pyUVM Docs**: https://pyuvm.github.io/pyuvm/
- **Cocotb Docs**: https://docs.cocotb.org/

## 💡 Tips

1. **Start Simple**: Run the default tests first before modifying
2. **Use Waveforms**: Always check waveforms when debugging
3. **Print Debugging**: Python's print() is your friend
4. **Incremental**: Make small changes and test frequently
5. **Clean Often**: Run `make clean` when changing DUT parameters

**Happy Testing! 🎉**
