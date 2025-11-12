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

### 4. Write Driver (`write_driver.v`)
- **Function**: Drive data onto bitlines during write operations
- **Architecture**:
  - **64 differential write drivers** (one per column)
  - **Differential outputs**: BL and BL̄ (128 total lines)
  - **Interleaved data organization** matching column mux
  - **2-stage buffer chains** for strong bitline drive
  - Tri-state outputs (high-Z when not writing)
  - Enable logic: `write_en & col_select[word]`
- **Interface**:
  - Input: `data_in[3:0]`, `col_select[15:0]`, `write_en`
  - Output: `bitline[63:0]`, `bitline_bar[63:0]` (differential)
- **Operation**:
  - Each column driven by one data bit when its word is selected
  - Column i: drives `data_in[i%4]` and complement to BL/BL̄
- **Test**: `make COMPONENT=write_driver`

### 5. Control FSM (`sram_control.v`)
- **Function**: Coordinate read/write operations with 2-cycle timing
- **Architecture**:
  - **3-state FSM**: IDLE, CYCLE1, CYCLE2
  - **50MHz operation** (20ns per cycle, 40ns total per operation)
  - Rising edge only (robust timing)
- **States**:
  - **IDLE**: Wait for enable signal, READY=1
  - **CYCLE1**: Row decode + precharge/column decode
  - **CYCLE2**: Sense amplify (read) or write drivers (write), READY=1
- **Interface**:
  - Input: `clk`, `rst_n`, `enable`, `read_not_write`
  - Output: `row_enable`, `col_enable`, `write_enable`, `read_enable`, `ready`

### 6. SRAM Core (`sram_core.v`)
- **Function**: Top-level SRAM integration
- **Integrates**:
  - Control FSM
  - Row Decoder
  - Column Decoder
  - Column Mux (read path)
  - Write Drivers (write path)
- **Interface**:
  - Input: `addr[9:0]`, `data_in[3:0]`, `enable`, `read_not_write`
  - Output: `data_out[3:0]`, `ready`
  - Memory array signals: `wordline[63:0]`, `bitline[63:0]`, `bitline_bar[63:0]`, `sense_data[63:0]`

### 7. Shared Utilities (`sram_utils.v`)
- **wordline_driver**: 2-stage non-inverting buffer for row/column decoders
- **bitline_driver**: 2-stage buffer for write driver outputs

## Test Results

✅ **Component Tests:**
- Row Decoder: PASS (5/5 tests)
- Column Decoder: PASS (5/5 tests)
- Column Mux: PASS (5/5 tests)
- Write Driver: PASS (6/6 tests)

✅ **Integration Test:** PASS
- Write operations: 5 addresses tested
- Read operations: All data verified
- Overwrite: Verified
- Back-to-back operations: Verified
- **Total: 14 operations, 100% success**

## Operation Timing

### Read Operation (2 cycles, 40ns total):
1. **Cycle 1 (0-20ns)**: Row decode → activate wordline, precharge bitlines
2. **Cycle 2 (20-40ns)**: Sense amplify → column mux → data_out valid, READY=1

### Write Operation (2 cycles, 40ns total):
1. **Cycle 1 (0-20ns)**: Row + column decode
2. **Cycle 2 (20-40ns)**: Write drivers active → data written to cells, READY=1

## TinyTapeout Integration

**Pin Mapping:**
- `ui_in[7:0]`: ADDR[7:0]
- `uio_in[7:6]`: ADDR[9:8]
- `uio_in[5]`: READ_NOT_WRITE (1=read, 0=write)
- `uio_in[4]`: ENABLE
- `uio_in[3:0]`: DATA_IN[3:0]
- `uo_out[3:0]`: DATA_OUT[3:0]
- `uo_out[4]`: READY

**Memory Array Interface** (for analog blocks):
- `wordline[63:0]`: To memory cells
- `bitline[63:0]`, `bitline_bar[63:0]`: Differential bitlines
- `sense_data[63:0]`: From sense amplifiers

**Note**: For simulation, a behavioral memory model (`sram_array_stub`) is included in `project.v`. For tapeout, replace with actual analog memory array, sense amps, and P/EQ circuitry.

