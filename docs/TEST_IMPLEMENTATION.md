# Test Implementation

## Overview

Due to time constraints and other factors, we are creating an **analog submission** which tests each component separately and in combinations. This allows us to verify individual component functionality before full integration.

---

## Test Selection

We use `ui_in[7:5]` as inputs to a **3:8 control decoder**. This enables one of 8 test circuits.

**Pin Mapping:**
- `ui_in[5]` → `addr[0]` (LSB)
- `ui_in[6]` → `addr[1]`
- `ui_in[7]` → `addr[2]` (MSB)

| `ui[7]` | `ui[6]` | `ui[5]` | Decoder Output | Test Circuit |
|---------|---------|---------|----------------|--------------|
| 0 | 0 | 0 | 0 | 6T Cell Test |
| 0 | 0 | 1 | 1 | Multi-Component Test (6T Cell) |
| 0 | 1 | 0 | 2 | Control FSM (Digital) |
| 0 | 1 | 1 | 3 | P/EQ Test |
| 1 | 0 | 0 | 4 | Multi-Component Test (NMOS Cell) |
| 1 | 0 | 1 | 5 | Sense Amp Test |
| 1 | 1 | 0 | 6 | Diff Amp Test |
| 1 | 1 | 1 | 7 | NMOS Cell Test |

---

## Individual Component Tests

### Test 0: 6T Cell Test
Tests the 6-transistor SRAM bitcell design.

![6T Cell Test Circuit](./images/6T%20cell.png)

### Test 3: P/EQ Test
Tests the Precharge/Equalize circuit for bitline conditioning.

![P/EQ Test Circuit](./images/P%3AEQ.png)

### Test 5: Sense Amp Test
Tests the sense amplifier component.

![Sense Amp Test Circuit](./images/Sense%20Amp.png)

### Test 6: Diff Amp Test
Tests the differential amplifier component.

![Diff Amp Test Circuit](./images/Diff%20Amp.png)

### Test 7: NMOS Cell Test
Tests the NMOS-based bitcell design.

![NMOS Cell Test Circuit](./images/NMOS%20cell.png)

---

## Digital Test

### Test 2: Control FSM

Tests the Control FSM to verify the sequence of signals and monitor delays/latency from the clock.

**Inputs:**
| Pin | Signal |
|-----|--------|
| `clk` | System clock |
| `rst_n` | Active-low reset |
| `ui_in[4]` | Read/Write select |
| Control decoder output 2 | Enable |

**Outputs (active high):**
| Pin | Signal | Description |
|-----|--------|-------------|
| `uo_out[0]` | `write_enable` | Write driver enable |
| `uo_out[1]` | `read_enable` | Sense amp/mux enable |
| `uo_out[2]` | `precharge_enable` | P/EQ circuit enable |
| `uo_out[3]` | `col_enable` | Column decoder enable |
| `uo_out[4]` | `row_enable` | Row decoder enable |
| `uo_out[5]` | `ready` | Operation complete flag |

This test allows monitoring of FSM state transitions and timing characteristics.

---

## Multi-Component Integration Tests

These tests simulate the **flow of a read and write operation to a single bit** by connecting multiple analog components together.

### Circuit Structure

```
               ┌─────────────┐
               │   P/EQ      │
               │  Component  │
               └──────┬──────┘
                      │
              BL ─────┼───── BLB
                      │
               ┌──────┴──────┐
               │   Bitcell   │
               │ (6T or NMOS)│
               └──────┬──────┘
                      │
              BL ─────┼───── BLB
                      │
               ┌──────┴──────┐
               │  Sense Amp  │
               └─────────────┘
```

### Test 1: Multi-Component Test with 6T Cell

- P/EQ component with BL/BLB outputs connected to **6T bitcell**
- BL/BLB lines also connected to sense amplifier
- Tests complete read/write path through 6T cell design

![Multi-Component Test with 6T Cell](./images/6T%20multi.png)

### Test 4: Multi-Component Test with NMOS Cell

- P/EQ component with BL/BLB outputs connected to **NMOS bitcell**
- BL/BLB lines also connected to sense amplifier
- Tests complete read/write path through NMOS cell design

![Multi-Component Test with NMOS Cell](./images/NMOS%20Multi.png)

### How to Test Multi-Component Circuits

These circuits simulate reading and writing from a single cell.

#### Read Operation

1. **Precharge**: Set P/EQ enable HIGH using analog pin `ua[3]`
2. **Release precharge**: Turn off `ua[3]`
3. **Select circuit**: Set pins to select the appropriate test:
   - **6T Cell (Test 1)**: `ui[7]=0`, `ui[6]=0`, `ui[5]=1`
   - **NMOS Cell (Test 4)**: `ui[7]=1`, `ui[6]=0`, `ui[5]=0`
4. This powers the wordline and unlocks the switch controlling the output
5. **Read output**: Observe the diff amp output on analog pin `ua[2]`

#### Write Operation

1. **Select circuit**: Set `ui_in[7:5]` to select the appropriate test (see above)
2. **Drive bitlines**:
   - Assert `ua[0]` to the desired value
   - Assert `ua[1]` to the **opposite** value (differential write)

---

## Test Circuit Images

All test circuit schematics are available in the `docs/images/` directory:

| Test | Image Available |
|------|-----------------|
| Test 0: 6T Cell | ✅ |
| Test 1: Multi-Component (6T) | ✅ |
| Test 2: Control FSM | ❌ (digital, no schematic) |
| Test 3: P/EQ | ✅ |
| Test 4: Multi-Component (NMOS) | ✅ |
| Test 5: Sense Amp | ✅ |
| Test 6: Diff Amp | ✅ |
| Test 7: NMOS Cell | ✅ |

---

## Summary

| Test | Type | Components Tested |
|------|------|-------------------|
| 0 | Analog | 6T bitcell only |
| 1 | Integration | P/EQ + 6T Cell + Sense Amp |
| 2 | Digital | Control FSM |
| 3 | Analog | P/EQ only |
| 4 | Integration | P/EQ + NMOS Cell + Sense Amp |
| 5 | Analog | Sense Amp only |
| 6 | Analog | Diff Amp only |
| 7 | Analog | NMOS bitcell only |

