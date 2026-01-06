# Doubly Linked List pyUVM VIP User Guide

## Overview

Complete pyUVM-based Verification IP for Doubly Linked List verification with **bidirectional pointers** (both prev and next).

## 🚀 Quick Start

```bash
cd Doubly_Linked_List/vip/pyuvm
make                         # Run all tests
gtkwave doubly_linked_list.vcd  # View waveforms
```

## 📋 Doubly Linked List Operations

Supports 6 operations with **bidirectional traversal**:

| Operation | Description | Op Code |
|-----------|-------------|---------|
| **READ_ADDR** | Read data at address (returns data, prev, next) | 0 |
| **INSERT_AT_ADDR** | Insert data at address | 1 |
| **DELETE_VALUE** | Delete by value | 2 |
| **DELETE_AT_ADDR** | Delete at address | 3 |
| **INSERT_AT_INDEX** | Insert at index | 5 |
| **DELETE_AT_INDEX** | Delete at index | 7 |

## Key Feature: Bidirectional Pointers

Unlike singly linked lists, **doubly linked lists track both**:
- `result_pre_addr` - Previous node pointer
- `result_next_addr` - Next node pointer

This enables **bidirectional traversal** and the scoreboard verifies both pointers.

## 🔧 Configuration

```python
cfg = DllVipConfig("cfg")
cfg.DATA_WIDTH = 8
cfg.MAX_NODE = 8
```

## ✅ Self-Checking

The scoreboard verifies:
- ✅ Data integrity
- ✅ **Both prev and next pointers**
- ✅ Insert/Delete operations
- ✅ List length tracking
- ✅ Head/tail management

## 📚 Example

```python
from sequences.dll_vip_insert_seq import DllVipInsertSeq

insert_seq = DllVipInsertSeq("insert_seq")
insert_seq.num_inserts = 5
await insert_seq.start(env.get_sequencer())
```

**Happy Verifying! 🐍🚀**
