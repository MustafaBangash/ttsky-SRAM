<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a complete single-tile SRAM module with the following architecture:

### Memory Organization
- **Capacity**: 4096 bits (64×64 bit array)
- **Word Size**: 4 bits
- **Words**: 1024 addressable words
- **Addressing**: 10-bit address (6 bits for row, 4 bits for column)

### Components
1. **Row Decoder (6:64)**: Decodes upper 6 address bits using NOR-based predecoders and an AND array to select one of 64 rows
2. **Column Decoder (4:16)**: Decodes lower 4 address bits to select one of 16 4-bit words per row
3. **Column Multiplexer**: Four parallel 16:1 muxes (one per bit) route the selected word to the output during reads
4. **Write Drivers**: 64 differential drivers (with 2-stage buffers) that drive BL/BL̄ pairs during writes
5. **Control FSM**: 2-cycle state machine that coordinates all operations at 50MHz
6. **Precharge Control**: Generates enable signal for bitline precharge/equalization circuit

### Operation
- **Read**: Takes 2 clock cycles (40ns total). In cycle 1, the row is decoded and bitlines are precharged. In cycle 2, sense amplifiers detect the cell data and the column mux routes the selected 4-bit word to the output.
- **Write**: Takes 2 clock cycles (40ns total). In cycle 1, row and column are decoded. In cycle 2, write drivers force the bitlines to the desired values and overwrite the selected cells.
- **Throughput**: 25 million operations per second (50MHz ÷ 2 cycles per operation)

### Design Decisions
- **Rising-edge only timing** for robustness across process/voltage/temperature variations
- **Differential bitlines** (BL/BL̄) to interface with standard 6T SRAM cells
- **2-stage buffer chains** on all decoder outputs and write drivers for strong drive capability
- **Interleaved column organization** to simplify routing between sense amplifiers and output

The digital components interface with analog blocks (memory cell array, sense amplifiers, and P/EQ circuitry) provided by other design teams via well-defined signal interfaces.

## How to test

### Pin Configuration

**Input Pins:**
- `ui_in[7:0]`: Address bits [7:0] (lower 8 bits)
- `uio_in[7:6]`: Address bits [9:8] (upper 2 bits)
- `uio_in[5]`: READ_NOT_WRITE control (1 = read, 0 = write)
- `uio_in[4]`: ENABLE (chip select)
- `uio_in[3:0]`: DATA_IN[3:0] (write data)

**Output Pins:**
- `uo_out[3:0]`: DATA_OUT[3:0] (read data)
- `uo_out[4]`: READY (1 = operation complete)

### Testing Procedure

**Write Operation:**
1. Set up the address on `ui_in[7:0]` and `uio_in[7:6]` (10 bits total)
2. Set the data to write on `uio_in[3:0]` (4 bits)
3. Set `uio_in[5]` = 0 (write mode)
4. Set `uio_in[4]` = 1 (enable)
5. Wait 2 clock cycles (40ns at 50MHz)
6. Check that `uo_out[4]` = 1 (READY)
7. Data is now stored at the specified address

**Read Operation:**
1. Set up the address on `ui_in[7:0]` and `uio_in[7:6]` (10 bits total)
2. Set `uio_in[5]` = 1 (read mode)
3. Set `uio_in[4]` = 1 (enable)
4. Wait 2 clock cycles (40ns at 50MHz)
5. Check that `uo_out[4]` = 1 (READY)
6. Read the data from `uo_out[3:0]`

**Example Test Sequence:**
```
Write 0xA to address 0x000:
  ui_in   = 0x00
  uio_in  = 0b00_0_1_1010  (addr[9:8]=00, R/W̄=0, EN=1, data=0xA)
  Wait 2 cycles
  Expect: uo_out[4] = 1

Read from address 0x000:
  ui_in   = 0x00
  uio_in  = 0b00_1_1_0000  (addr[9:8]=00, R/W̄=1, EN=1, data=X)
  Wait 2 cycles
  Expect: uo_out[3:0] = 0xA, uo_out[4] = 1
```

### Automated Testing
The repository includes comprehensive test suites:
- Component tests: `cd test && make COMPONENT=<component_name>`
- Integration test: `cd test && make`
- All tests: `cd test && make test_all`

All tests use cocotb (Python-based hardware verification) and generate VCD waveforms for inspection.

## External hardware

No external hardware is required. This is a standalone SRAM module that can be accessed entirely through the TinyTapeout I/O pins. The design includes a behavioral memory model for simulation, which will be replaced with actual analog memory components (6T SRAM cells, sense amplifiers, and precharge/equalization circuits) during tapeout.
