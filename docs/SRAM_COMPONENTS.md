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
  - No buffer chains (outputs drive digital logic only, not long analog lines)
- **Interface**:
  - Input: `addr[3:0]`, `enable`
  - Output: `col_select[15:0]` (one-hot)
- **Test**: `make COMPONENT=column_decoder`

### 3. Column Mux (`column_mux.v`)
- **Function**: Selects 4-bit word from 64 sense amplifier outputs
- **Architecture**:
  - **64 sense amplifiers** (one per BL/BL̄ pair) at bottom of array
  - **4 parallel 16:1 muxes** (one per bit position) select from sense amp outputs
  - **Interleaved column organization**:
    - Bit[0]: columns 0, 4, 8, ..., 60
    - Bit[1]: columns 1, 5, 9, ..., 61
    - Bit[2]: columns 2, 6, 10, ..., 62
    - Bit[3]: columns 3, 7, 11, ..., 63
  - OR-based mux structure
- **Interface**:
  - Input: `sense_data[63:0]` (from 64 sense amps), `col_select[15:0]`
  - Output: `data_out[3:0]`
- **Test**: `make COMPONENT=column_mux`

## Buffer Chains

Buffer chains are used **only** for driving long analog lines with significant capacitive load:

### Wordline Drivers (Row Decoder → Wordlines)
```
row_decoder → [INV] → [INV] → wordline[63:0]
```
Each wordline connects to 64 SRAM cells — needs strong drive.

### Bitline Drivers (Write Drivers → Bitlines)
```
write_logic → [TRI-STATE BUF] → bitline[63:0], bitline_bar[63:0]
```
Each bitline connects to 64 SRAM cells. In RTL, this is a pass-through to preserve tri-state (high-Z) behavior. In real silicon, this would be a sized tri-state buffer.

### No Buffers Needed
- **Column select lines**: Drive only digital gates (column mux, write driver logic) — short wires, no buffer needed

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
```

### View Waveforms
VCD files are generated in `test/waveforms/`. To view:
- **VS Code**: Click on any `.vcd` file with the [Surfer](https://marketplace.visualstudio.com/items?itemName=surfer-project.surfer) extension installed
- **GTKWave**: `gtkwave test/waveforms/tb.vcd`
- **Other**: Any VCD-compatible waveform viewer

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
- **Function**: Coordinate read/write operations with 3-cycle timing
- **Architecture**:
  - **4-state FSM**: IDLE, PRECHARGE, DEVELOP, SENSE
  - **50MHz operation** (20ns per cycle, 60ns total per operation)
  - Rising edge only (robust timing)
- **States**:
  - **IDLE**: Wait for enable signal, precharge active, READY=1
  - **PRECHARGE**: Bitlines equalize to VDD/2, column decode begins
  - **DEVELOP**: Wordline rises, ΔV develops on bitlines (~20ns)
  - **SENSE**: Sense amplify (read) or write drivers (write), READY=1
- **Interface**:
  - Input: `clk`, `rst_n`, `enable`, `read_not_write`
  - Output: `row_enable`, `col_enable`, `write_enable`, `read_enable`, `precharge_enable`, `ready`

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
- **wordline_driver**: 2-stage inverter buffer for row decoder → wordlines (strong drive)
- **bitline_driver**: Tri-state buffer placeholder for write drivers → bitlines (pass-through in RTL to preserve high-Z behavior; would be sized tri-state buffer in real silicon)

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

### Read Operation (3 cycles, 60ns total):
1. **PRECHARGE (0-20ns)**: Bitlines equalize to VDD/2, column decode active
2. **DEVELOP (20-40ns)**: Wordline rises, cell creates differential voltage on bitlines
3. **SENSE (40-60ns)**: Sense amplifiers fire, column mux routes data_out, READY=1

### Write Operation (3 cycles, 60ns total):
1. **PRECHARGE (0-20ns)**: Bitlines equalize, column decode active
2. **DEVELOP (20-40ns)**: Wordline rises, row/column fully decoded
3. **SENSE (40-60ns)**: Write drivers force bitlines to data values, READY=1

### Why 3 Cycles?
The 3-cycle design provides robust margins for analog operation:
- **PRECHARGE**: Full 20ns for bitline equalization (critical for sense amp accuracy)
- **DEVELOP**: Full 20ns for cell to create ΔV on bitlines (process-dependent)
- **SENSE**: Full 20ns for sense amp to resolve and stabilize output

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

