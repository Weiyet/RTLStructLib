# Table pyUVM VIP User Guide

## Overview

Complete pyUVM-based Verification IP for **Table** - multi-port read/write memory structure supporting simultaneous operations.

## Quick Start

```bash
cd Table/vip/pyuvm
make                     # Run test
gtkwave table_top.vcd    # View waveforms
```

## Table Features

**Key Capability**: Multi-port table with 2 simultaneous write ports and 2 simultaneous read ports

| Signal | Description | Width |
|--------|-------------|-------|
| `wr_en` | Write enable (2 ports) | 2 |
| `index_wr` | Write indices (packed) | 10 ([9:5]=idx[1], [4:0]=idx[0]) |
| `data_wr` | Write data (packed) | 16 ([15:8]=data[1], [7:0]=data[0]) |
| `rd_en` | Read enable | 1 |
| `index_rd` | Read indices (packed) | 10 ([9:5]=idx[1], [4:0]=idx[0]) |
| `data_rd` | Read data (packed) | 16 ([15:8]=data[1], [7:0]=data[0]) |

## Configuration

```python
cfg = TableVipConfig("cfg")
cfg.TABLE_SIZE = 32
cfg.DATA_WIDTH = 8
cfg.INPUT_RATE = 2   # Number of write ports
cfg.OUTPUT_RATE = 2  # Number of read ports
```

## Self-Checking

The scoreboard uses a Python dictionary as the table reference model:
- WRITE: Updates `table_model[index] = data` for each enabled write port
- READ: Compares `data_rd` with `table_model[index]` for each read port

## Example

```python
from sequences.table_vip_write_seq import TableVipWriteSeq
from sequences.table_vip_read_seq import TableVipReadSeq

# Write data
write_seq = TableVipWriteSeq("write_seq")
write_seq.num_trans = 10
await write_seq.start(env.get_sequencer())

# Read data
read_seq = TableVipReadSeq("read_seq")
read_seq.num_trans = 5
await read_seq.start(env.get_sequencer())
```

## Available Sequences

- `TableVipWriteSeq` - Write-only operations (multi-port)
- `TableVipReadSeq` - Read-only operations (multi-port)
- `TableVipRandomSeq` - Random READ/WRITE mix

## Use Cases

- Multi-port memory verification
- Lookup table testing
- Simultaneous read/write validation
- Register file verification

**Happy Verifying!**
