# Test Implementation

## Overview

Due to time constraints and other factors, we are creating an **analog submission** which tests each component separately and in combinations. This allows us to verify individual component functionality before full integration.

---

## Test Selection

We use `ui_in[7:5]` as inputs to a **3:8 control decoder**. This enables one of 8 test circuits:

| `ui_in[7:5]` | Test Circuit |
|--------------|--------------|
| `000` | Precharge/Equalize component |
| `001` | Bitcell component 1 |
| `010` | Bitcell component 2 |
| `011` | Sense amplifier component 1 |
| `100` | Sense amplifier component 2 |
| `101` | Control FSM (digital) |
| `110` | Single-bit read/write flow (bitcell 1) |
| `111` | Single-bit read/write flow (bitcell 2) |

---

## Individual Component Tests (Tests 0-5)

### Analog Tests (Tests 0-4)

Five analog component tests with inputs and outputs connected to analog pins, gated by switches:

| Test | Component | Description |
|------|-----------|-------------|
| 0 | Precharge/Equalize | Tests bitline equalization circuit |
| 1 | Bitcell 1 | Tests first bitcell design |
| 2 | Bitcell 2 | Tests second bitcell design |
| 3 | Sense Amp 1 | Tests first sense amplifier design |
| 4 | Sense Amp 2 | Tests second sense amplifier design |

### Digital Test (Test 5)

Tests the **Control FSM** to verify the sequence of signals and monitor delays/latency from the clock.

**Inputs:**
- `clk` — System clock
- `rst_n` — Active-low reset
- `ui_in[0]` — Read/Write select
- Control decoder output — Enable signal

**Outputs:**
- All FSM outputs connected to digital output pins

This test allows monitoring of FSM state transitions and timing characteristics.

---

## Integration Tests (Tests 6-7)

The last two circuits simulate the **flow of a read and write operation to a single bit**.

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
               │  (1 or 2)   │
               └──────┬──────┘
                      │
              BL ─────┼───── BLB
                      │
               ┌──────┴──────┐
               │  Sense Amp  │
               └─────────────┘
```

### Test 6: Single-Bit Flow with Bitcell 1

- P/EQ component with BL/BLB outputs connected to **Bitcell 1**
- BL/BLB lines also connected to sense amplifier
- Tests complete read/write path through first bitcell design

### Test 7: Single-Bit Flow with Bitcell 2

- P/EQ component with BL/BLB outputs connected to **Bitcell 2**
- BL/BLB lines also connected to sense amplifier
- Tests complete read/write path through second bitcell design

These integration tests verify that the analog components work together correctly in the actual SRAM signal flow.

---

## Summary

| Test | Type | Components Tested |
|------|------|-------------------|
| 0 | Analog | P/EQ only |
| 1 | Analog | Bitcell 1 only |
| 2 | Analog | Bitcell 2 only |
| 3 | Analog | Sense Amp 1 only |
| 4 | Analog | Sense Amp 2 only |
| 5 | Digital | Control FSM |
| 6 | Integration | P/EQ + Bitcell 1 + Sense Amp |
| 7 | Integration | P/EQ + Bitcell 2 + Sense Amp |


