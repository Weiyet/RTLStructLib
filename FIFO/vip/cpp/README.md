# FIFO VIP - C++ Implementation

C++ testbench for FIFO verification using Verilator, implementing UVM-style methodology.

## Overview

This VIP provides an equivalent verification approach to the pyUVM and SystemVerilog UVM implementations, but using pure C++ with Verilator. This enables:

- **Fast simulation** - Verilator compiles RTL to optimized C++
- **No license costs** - Fully open-source toolchain
- **C++ ecosystem** - Use modern C++ features, libraries, and tools
- **CI/CD friendly** - Easy integration into automated pipelines

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Testbench (main)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐     ┌───────────────┐    ┌────────────┐  │
│  │ FifoDriver   │────>│ FifoMonitor   │───>│ FifoScore  │  │
│  │              │     │               │    │  board     │  │
│  └──────┬───────┘     └───────────────┘    └────────────┘  │
│         │                                                   │
│         │             ┌───────────────┐                     │
│         └────────────>│ FifoCoverage  │                     │
│                       └───────────────┘                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │    Vfifo (DUT)        │
              │   (Verilated Model)   │
              └───────────────────────┘
```

## Component Mapping

| UVM/pyUVM Concept | C++ Implementation | File |
|-------------------|-------------------|------|
| Sequence Item | `FifoTransaction` | `fifo_transaction.h` |
| Driver | `FifoDriver<T>` | `fifo_driver.h` |
| Monitor | `FifoMonitor<T>` | `fifo_monitor.h` |
| Scoreboard | `FifoScoreboard` | `fifo_scoreboard.h` |
| Coverage | `FifoCoverage` | `fifo_coverage.h` |
| Environment/Test | `main()` | `fifo_tb.cpp` |

## Prerequisites

- **Verilator** (version 4.0+)
- **C++17** compatible compiler (g++, clang++)
- **Make**
- **GTKWave** (optional, for waveform viewing)

### Installation

Ubuntu/Debian:
```bash
sudo apt install verilator gtkwave
```

macOS:
```bash
brew install verilator gtkwave
```

## Usage

### Build
```bash
make
```

### Run Simulation
```bash
make run                # Standard run
make run-verbose        # With detailed output
make run-nowaves        # Without VCD generation (faster)
```

### View Waveforms
```bash
make waves              # Opens GTKWave
```

### Runtime Options
```bash
./obj_dir/Vfifo [options]

Options:
  -v, --verbose     Enable verbose output
  --no-waves        Disable VCD waveform generation
  --seed=N          Set random seed (default: 12345)
  --writes=N        Number of write transactions (default: 20)
  --reads=N         Number of read transactions (default: 20)
```

## Test Sequences

### 1. Simple Test
Directed test that:
- Fills the FIFO completely
- Attempts write when full (verifies full flag)
- Drains the FIFO completely
- Attempts read when empty (verifies empty flag)

### 2. Random Test
Randomized test with:
- Random data values
- Mixed read/write operations
- Two phases: fill-heavy then drain-heavy

### 3. Stress Test
Back-to-back operations:
- Multiple rapid fill/drain cycles
- Exercises full/empty transitions

## Self-Checking

The scoreboard maintains a reference model (C++ `std::queue`) that:
- Mirrors all DUT operations
- Verifies read data matches expected values
- Tracks full/empty flag consistency
- Reports errors at end of simulation

## Coverage Metrics

The coverage collector tracks:

| Category | Metrics |
|----------|---------|
| Operation | WRITE, READ operations exercised |
| Data | Unique data values written/read |
| Fill Level | All FIFO occupancy levels (0 to DEPTH) |
| Corner Cases | Full, Empty, Write-when-full, Read-when-empty |

## Output Example

```
==================================================
FIFO VIP Scoreboard Report
==================================================
Total Writes:        45
Total Reads:         45
Writes when Full:    5
Reads when Empty:    3
Errors:              0
Final Queue Size:    0

*** TEST PASSED ***
==================================================

==================================================
FIFO VIP Coverage Report
==================================================

Operation Coverage:
  WRITE:    YES
  READ:     YES
  Coverage: 100.0%

Fill Level Coverage:
  Levels Seen: 0 1 2 3 4 5 6 7 8 9 10 11 12
  Coverage: 100.0%

Corner Case Coverage:
  FIFO Full Seen:      YES
  FIFO Empty Seen:     YES
  Write When Full:     YES
  Read When Empty:     YES
  Coverage: 100.0%

Overall Coverage: 95.2%
==================================================
```

## Extending to Other Modules

To create a C++ VIP for another module (e.g., DLL, LIFO):

1. Copy this directory structure
2. Create module-specific transaction class with appropriate fields
3. Implement driver methods for module operations
4. Implement scoreboard reference model
5. Define relevant coverage bins

## Comparison with pyUVM/UVM

| Aspect | C++ | pyUVM | UVM (SV) |
|--------|-----|-------|----------|
| Simulation Speed | Fastest | Medium | Slowest |
| License Cost | Free | Free* | Paid** |
| Randomization | Manual | Built-in | Built-in |
| Coverage | Manual | Manual | Built-in |
| Learning Curve | Moderate | Low | High |
| Ecosystem | C++ libraries | Python libs | SV/UVM libs |

\* Requires cocotb + simulator
\** Requires commercial simulator

## Files

```
fifo/vip/cpp/
├── README.md              # This file
├── Makefile               # Build automation
├── fifo_transaction.h     # Transaction class
├── fifo_driver.h          # Driver class
├── fifo_monitor.h         # Monitor class
├── fifo_scoreboard.h      # Scoreboard with reference model
├── fifo_coverage.h        # Coverage collector
└── fifo_tb.cpp            # Main testbench
```
