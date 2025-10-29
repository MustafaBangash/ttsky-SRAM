# SRAM Components Documentation

## Overview

This SRAM design uses a 64×64 bit array organized as 64 rows × 16 words, with 4-bit words.

## Architecture

```
Address: 10 bits total
├─ Row Address [9:4]: 6 bits → Row Decoder (6:64) → 64 wordlines
└─ Column Address [3:0]: 4 bits → Column Decoder (4:16) → 16 word selects

Memory Array: 64 rows × 64 columns
Output: 4-bit word (selected via column mux)
```

## Components

### 1. Row Decoder (`row_decoder.v`)
- **Function**: Decodes 6-bit address to select 1 of 64 rows
- **Architecture**: 
  - Two 3:8 NOR-based predecoders
  - 8×8 AND array
  - 2-stage inverter buffer chains on each output to drive wordlines
- **Interface**:
  - Input: `addr[5:0]`, `enable`
  - Output: `row_select[63:0]` (one-hot)
- **Test**: `make COMPONENT=row_decoder`

### 2. Column Decoder (`column_decoder.v`)
- **Function**: Decodes 4-bit address to select 1 of 16 words
- **Architecture**:
  - Two 2:4 predecoders
  - 4×4 AND array
  - 2-stage inverter buffer chains for driving column select lines
- **Interface**:
  - Input: `addr[3:0]`, `enable`
  - Output: `col_select[15:0]` (one-hot)
- **Test**: `make COMPONENT=column_decoder`

### 3. Column Mux (`column_mux.v`)
- **Function**: Selects 4-bit word from 64 columns based on column decoder output
- **Architecture**:
  - **4 parallel 16:1 muxes** (one per bit position)
  - **Interleaved column organization**:
    - Bit[0]: columns 0, 4, 8, ..., 60
    - Bit[1]: columns 1, 5, 9, ..., 61
    - Bit[2]: columns 2, 6, 10, ..., 62
    - Bit[3]: columns 3, 7, 11, ..., 63
  - Each mux feeds a separate sense amplifier
  - OR-based mux structure
- **Interface**:
  - Input: `col_data[63:0]`, `col_select[15:0]`
  - Output: `data_out[3:0]`
- **Test**: `make COMPONENT=column_mux`

## Buffer Chains

### Wordline Drivers
Each decoder output drives a wordline through a 2-stage inverter chain:
```
signal → [INV] → [INV] → buffered_output
```

**Purpose**: 
- Provides strong drive capability for long wordlines
- 2 stages = non-inverting (maintains signal polarity)
- Increases slew rate and reduces delay

## Testing

Each component has:
1. **Verilog module** (`src/*.v`)
2. **Testbench wrapper** (`test/tb_*.v`)
3. **Cocotb test** (`test/test_*.py`)

### Run Tests
```bash
cd test

# Test individual components
make COMPONENT=row_decoder
make COMPONENT=column_decoder
make COMPONENT=column_mux

# View waveforms
gtkwave tb.vcd
```

## Test Results

✅ Row Decoder: PASS (5/5 tests)
✅ Column Decoder: PASS (5/5 tests)
✅ Column Mux: PASS (5/5 tests)

## Next Steps

To complete the SRAM, you'll need:
1. **Memory Array** (64×64 bit cells)
2. **Write Drivers** (for write operations)
3. **Sense Amplifiers** (for read operations)
4. **Control Logic** (read/write sequencing)
5. **Integration** (connect all components in `project.v`)

