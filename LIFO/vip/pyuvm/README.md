# LIFO pyUVM VIP User Guide

## Overview

Complete pyUVM-based Verification IP for **Last-In-First-Out (LIFO) Stack** - standard stack data structure.

## Quick Start

```bash
cd LIFO/vip/pyuvm
make                     # Run test
gtkwave lifo.vcd         # View waveforms
```

## LIFO Features

**Key Capability**: Last-In-First-Out stack with PUSH and POP operations

| Signal | Description | Width |
|--------|-------------|-------|
| `data_wr` | Write data for PUSH | DATA_WIDTH |
| `wr_en` | Write enable (PUSH) | 1 |
| `rd_en` | Read enable (POP) | 1 |
| `data_rd` | Read data from POP | DATA_WIDTH |
| `lifo_full` | Stack full flag | 1 |
| `lifo_empty` | Stack empty flag | 1 |

## Configuration

```python
cfg = LifoVipConfig("cfg")
cfg.DEPTH = 12
cfg.DATA_WIDTH = 8
```

## Self-Checking

The scoreboard uses a Python list as the LIFO reference model:
- PUSH: `list.append(data)` - adds to end
- POP: `list.pop()` - removes from end (LIFO behavior)

## Example

```python
from sequences.lifo_vip_push_seq import LifoVipPushSeq
from sequences.lifo_vip_pop_seq import LifoVipPopSeq

# Push data
push_seq = LifoVipPushSeq("push_seq")
push_seq.num_trans = 10
await push_seq.start(env.get_sequencer())

# Pop data
pop_seq = LifoVipPopSeq("pop_seq")
pop_seq.num_trans = 5
await pop_seq.start(env.get_sequencer())
```

## Available Sequences

- `LifoVipPushSeq` - Push-only operations
- `LifoVipPopSeq` - Pop-only operations
- `LifoVipRandomSeq` - Random PUSH/POP mix

## Use Cases

- Stack data structure verification
- LIFO behavior validation
- Full/empty flag checking
- Bypass operation testing (simultaneous push/pop)

**Happy Verifying!**
