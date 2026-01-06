# Doubly Linked List pyUVM VIP - Files Created

## Complete File List (24 files total)

### Key Difference from Singly Linked List
**Doubly Linked List** tracks **both prev and next pointers** for bidirectional traversal.

### 📂 Root Directory (6 files)
- ✅ `__init__.py`
- ✅ `Makefile`
- ✅ `tb_dll.py`
- ✅ `README.md`
- ✅ `QUICKSTART.md` (coming soon)
- ✅ `FILES_CREATED.md`

### 📂 common/ (4 files)
- ✅ `dll_vip_types.py` - DllOp enum
- ✅ `dll_vip_config.py`
- ✅ `dll_vip_seq_item.py` - Includes `result_pre_addr` and `result_next_addr`

### 📂 agent/ (5 files)
- ✅ `dll_vip_driver.py` - Captures both prev and next
- ✅ `dll_vip_monitor.py` - Monitors both pointers
- ✅ `dll_vip_sequencer.py`
- ✅ `dll_vip_agent.py`

### 📂 env/ (3 files)
- ✅ `dll_vip_scoreboard.py` - Verifies both prev and next pointers
- ✅ `dll_vip_env.py`

### 📂 sequences/ (4 files)
- ✅ `dll_vip_base_seq.py`
- ✅ `dll_vip_insert_seq.py`
- ✅ `dll_vip_read_seq.py`
- ✅ `dll_vip_delete_seq.py`

### 📂 tests/ (3 files)
- ✅ `dll_vip_base_test.py`
- ✅ `dll_vip_simple_test.py`

## How to Use

```bash
cd Doubly_Linked_List/vip/pyuvm
make
gtkwave doubly_linked_list.vcd
```

## Doubly vs Singly Linked List

| Feature | Singly | Doubly |
|---------|--------|--------|
| **Prev Pointer** | ❌ No | ✅ Yes |
| **Next Pointer** | ✅ Yes | ✅ Yes |
| **Traversal** | Forward only | **Bidirectional** |
| **Scoreboard Check** | Next only | **Both prev & next** |

**Happy Verifying! 🐍🚀**
