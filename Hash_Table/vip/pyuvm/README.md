# Hash Table pyUVM VIP User Guide

This legacy VIP currently fails during Python imports. Its Makefile uses
`../../../Utils/vip/pyuvm/Makefile`; use `../../tb/` for standalone RTL verification.

## Overview

Complete pyUVM-based Verification IP for Hash Table verification with **key-value pair operations**.

## 🚀 Quick Start

```bash
cd Hash_Table/vip/pyuvm
make WAVES=1                      # Run all tests
gtkwave sim_build/hash_table.fst    # View waveforms
```

## 📋 Hash Table Operations

Supports 3 operations on **key-value pairs**:

| Operation | Description | Op Code |
|-----------|-------------|---------|
| **INSERT** | Insert key-value pair | 0 |
| **DELETE** | Delete by key | 1 |
| **SEARCH** | Search by key, return value | 2 |

## Key Features

✅ **Key-Value Pairs** - Store and retrieve data using keys
✅ **Collision Handling** - Multi-stage chaining support
✅ **Hash Functions** - MODULUS, FNV1A, SHA1 algorithms
✅ **Python Dict Model** - Uses Python dictionary as reference
✅ **Self-Checking** - Automatic scoreboard verification

## 🔧 Configuration

```python
cfg = HtVipConfig("cfg")
cfg.KEY_WIDTH = 32
cfg.VALUE_WIDTH = 32
cfg.TOTAL_INDEX = 8
cfg.CHAINING_SIZE = 4
cfg.COLLISION_METHOD = "MULTI_STAGE_CHAINING"
cfg.HASH_ALGORITHM = "MODULUS"
```

## ✅ Scoreboard Verification

The scoreboard uses a **Python dictionary** as the reference model:
- INSERT: Adds key-value pair to dict
- DELETE: Removes key from dict
- SEARCH: Verifies returned value matches dict

## 📚 Example

```python
from sequences.ht_vip_insert_seq import HtVipInsertSeq

insert_seq = HtVipInsertSeq("insert_seq")
insert_seq.num_inserts = 5
await insert_seq.start(env.get_sequencer())
```

## 🎯 Use Cases

- Hash table collision testing
- Key-value store verification
- Hash algorithm validation
- Performance analysis (collision_count tracking)

**Happy Verifying! 🐍🚀**
