# SRAM Design Considerations

## Overview

This document explains the design trade-offs and constraints that shaped our SRAM architecture, particularly around word size, address space, and I/O limitations.

---

## 1. TinyTapeout I/O Constraints

TinyTapeout provides limited I/O pins:

| Pin Type | Count | Direction |
|----------|-------|-----------|
| `ui_in` | 8 | Input only |
| `uo_out` | 8 | Output only |
| `uio` | 8 | Bidirectional |

### Write Operation Constraints

During a **write operation**, we need to provide:
- Address bits
- Data bits
- Control signals (enable, read/write)

All inputs must come from `ui_in[7:0]` (8 bits) + `uio[7:0]` configured as inputs (8 bits) = **16 bits total**.

With 2 bits reserved for control signals:
- `ENABLE` (1 bit)
- `READ_NOT_WRITE` (1 bit)

This leaves **14 bits** for address + data combined.

### Timing Constraints

The maximum clock frequency for a TinyTapeout chip is 66MHz. We aimed for 50MHz operation. However, we later discovered that while 66MHz is the max clock speed, the **maximum output frequency is 33MHz**. This eliminated the possibility of single-cycle operation.

Additionally, the TinyTapeout documentation states:

> We expect a latency (insertion delay) of up to 10 nanoseconds between the chip's I/O pad and your project's clock.

This 10ns latency created difficulty with having different control signals fire in the same clock period using rising and falling edges. To account for this latency, we had to separate the read operation into **three cycles**:

1. **PRECHARGE** (20ns): Bitlines equalize
2. **DEVELOP** (20ns): Wordline rises, differential voltage develops
3. **SENSE** (20ns): Sense amplifiers fire, data output valid

This 3-cycle approach ensures robust timing margins despite the I/O latency.

---

## 2. Memory Capacity vs Word Size Trade-off

The fundamental trade-off:

```
Address bits + Data bits = 14 (fixed by I/O constraints)

Memory capacity = 2^(address_bits) × word_size
                = 2^(14 - word_size) × word_size
```

### Analysis

| Word Size | Address Bits | Words | Total Bits | Efficiency |
|-----------|--------------|-------|------------|------------|
| 1 bit | 13 | 8,192 | 8,192 | High count, tiny words |
| 2 bits | 12 | 4,096 | 8,192 | |
| **4 bits** | **10** | **1,024** | **4,096** | **Optimal balance** |
| 8 bits | 6 | 64 | 512 | Few words, large data |
| 14 bits | 0 | 1 | 14 | Single register |

### With 2-bit Control Overhead (14 bits for address+data)

![Memory capacity vs word size with 14 bits available](./images/14%20bit%20graph.png)

### Theoretical Maximum (16 bits for address+data)

![Memory capacity vs word size with 16 bits available](./images/16%20bit%20graph.png)

---

## 3. Why We Chose 4-Bit Word Size

### Memory Capacity
- **10 address bits** → 1,024 addressable words
- **4-bit words** → 4,096 total bits of storage

### Physical Feasibility
Assuming a **√3μm × √3μm (3μm²) bitcell**:
- 4,096 cells × 3μm² = 12,288 μm²
- TinyTapeout tile area = 160μm × 100μm = **16,000 μm²**
- Memory array uses ~77% of tile area → **tight but feasible**

This leaves ~3,700 μm² for peripheral circuits (decoders, sense amps, control logic).

### Comparison with 8-Bit Word Size
| Metric | 4-bit | 8-bit |
|--------|-------|-------|
| Address bits | 10 | 6 |
| Words | 1,024 | 64 |
| Total bits | 4,096 | 512 |
| Capacity ratio | 8× more | baseline |

An 8-bit word size would waste 87.5% of potential storage capacity due to insufficient address bits.

---

## 4. Pin Assignment Summary

### Our Design (4-bit word, 10-bit address)

**Inputs (16 bits used):**
| Signal | Pins | Bits |
|--------|------|------|
| `ADDR[7:0]` | `ui_in[7:0]` | 8 |
| `ADDR[9:8]` | `uio_in[7:6]` | 2 |
| `READ_NOT_WRITE` | `uio_in[5]` | 1 |
| `ENABLE` | `uio_in[4]` | 1 |
| `DATA_IN[3:0]` | `uio_in[3:0]` | 4 |
| **Total** | | **16** |

**Outputs:**
| Signal | Pins | Bits |
|--------|------|------|
| `DATA_OUT[3:0]` | `uo_out[3:0]` | 4 |
| `READY` | `uo_out[4]` | 1 |
| (unused) | `uo_out[7:5]` | 3 |

---

## 5. Future Considerations

### Time-Multiplexed Addressing

**Concept**: Consider using separate address and data by splitting data input into multiple clock cycles, removing the 14-bit constraint.

```
Cycle 1: Input address (all 16 bits available → 16-bit address)
Cycle 2: Input data (all 16 bits available → 16-bit word)
Cycle 3+: Execute operation
```

**Benefits**:
- 16-bit address → 65,536 words
- 16-bit word size
- Total capacity: 65,536 × 16 = **1,048,576 bits (1 Mbit)**

**Trade-offs**:
- You would need a more complex control FSM (additional states for address latch)
- Slower access time (extra cycles for address input)
- Requires address register/latch circuitry

### Component Size Optimization

The curent constraint on memory capacity is **physical area**, we had assumed for much smaller components. If you are able to improve on this size in the future, the you can consider the time-multiplexing. 

**Note**: With 16,000 μm² total tile area and 12,288 μm² for the memory array, only ~3,700 μm² remains for all peripheral circuits.

---

## 6. Assembly Notes

### Compilation Challenges

Trying to compile all the digital circuitry together proved to be difficult as unused logic gets optimized away by the compiler, and we cannot control the layout of all the components. We tried using fillers or components in the space of the bitcells and other analog components so we could replace them later, but we were unsuccessful with this approach.

### Component-by-Component Compilation

We decided to compile each component separately. This was done using OpenLane in order to create components which can be imported into Magic. The components can then be manually wired together and attached to the sense amps, P/EQ circuits, and the bitcells.

The existing GDS files can be found in the `gds_files/` directory. Based on your design modifications, you would need to modify the Verilog in the `src/` directory and recompile.

### Repository Structure

The top module in this repo is not meant for synthesis and is just used to create a test component used in the cocotb tests. The actual submission for this test run will be an analog submission.

### Analog Submission Notes

In an analog submission you need a minimum of two tiles, so if the final module is an analog submission then the memory capacity should be able to be doubled.

In an analog submission you need to configure a separate repository and upload the GDS file there.

---

## 7. Summary

| Parameter | Value | Constraint |
|-----------|-------|------------|
| Word size | 4 bits | Optimized for capacity |
| Address space | 10 bits | I/O limited (14 - 4 = 10) |
| Total words | 1,024 | 2^10 |
| Total capacity | 4,096 bits | 1,024 × 4 |
| Array organization | 64 rows × 64 columns | √4096 = 64 |
| Access time | 60ns (3 cycles @ 50MHz) | FSM timing |

The 4-bit word size represents the optimal balance between storage capacity and practical usability within TinyTapeout's I/O constraints.


