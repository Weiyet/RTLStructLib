# Dual Edge FF pyUVM VIP User Guide

This legacy VIP currently fails during Python imports. Its Makefile uses
`../../../Utils/vip/pyuvm/Makefile`; use `../../tb/` for standalone RTL verification.

## Overview

Complete pyUVM-based Verification IP for **Dual Edge Flip-Flop** - latches data on **both positive and negative clock edges**.

## 🚀 Quick Start

```bash
cd Dual_Edge_FF/vip/pyuvm
make WAVES=1                     # Run test
gtkwave sim_build/dual_edge_ff.fst # View waveforms
```

## 📋 Dual Edge FF Features

**Key Capability**: Latch data on **BOTH clock edges** (pos and neg)

| Signal | Description | Width |
|--------|-------------|-------|
| `data_in` | Input data | DATA_WIDTH |
| `pos_edge_latch_en` | Positive edge latch enable (per bit) | DATA_WIDTH |
| `neg_edge_latch_en` | Negative edge latch enable (per bit) | DATA_WIDTH |
| `data_out` | Output data | DATA_WIDTH |

## 🔧 Configuration

```python
cfg = DeffVipConfig("cfg")
cfg.DATA_WIDTH = 8
cfg.RESET_VALUE = 0x00
```

## ✅ Self-Checking

The scoreboard tracks FF state through dual-edge operations.

## 📚 Example

```python
from sequences.deff_vip_random_seq import DeffVipRandomSeq

rand_seq = DeffVipRandomSeq("rand_seq")
rand_seq.num_trans = 20
await rand_seq.start(env.get_sequencer())
```

## 🎯 Use Cases

- Double data rate (DDR) verification
- Dual-edge triggered circuit testing
- Per-bit latch enable validation

**Happy Verifying! 🐍🚀**
