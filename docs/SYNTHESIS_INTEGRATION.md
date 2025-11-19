# Synthesis and Magic Integration Guide

## Changes Made for GDS Generation

This document explains the changes made to prepare your digital SRAM logic for GDS generation and subsequent Magic integration with analog blocks.

## 1. Memory Stub Conditional Compilation

**File: `src/sram_core.v`**

The behavioral memory array is now wrapped in conditional compilation:

```verilog
`ifndef SYNTHESIS
    // Memory stub exists here for RTL simulation
    reg [63:0] memory [0:63];
    // ... simulation logic ...
`else
    // For synthesis: minimal logic to prevent floating wires
    assign sense_data = 64'h0;
`endif
```

### What This Does:

- **RTL Simulation (local tests)**: Memory stub is included → tests work normally
- **Synthesis (GDS generation)**: Memory stub is excluded → clean digital logic only
- **Result**: No flip-flops synthesized for memory array (saves ~4096 FFs!)

## 2. Gate-Level Test Disabled

**File: `.github/workflows/gds.yaml`**

The `gl_test` job has been commented out because:

1. Your design is **digital-only** (no memory cells)
2. GL simulation would test a chip without memory → will always read zeros
3. The real test happens after Magic integration

## 3. What Gets Synthesized

Your GDS file will contain **only**:

### Digital Components (Synthesized):
- ✅ Row Decoder (6:64 with 3:8 predecoders)
- ✅ Column Decoder (4:16)
- ✅ Column Mux (4 parallel 16:1 muxes)
- ✅ Write Drivers (64 differential drivers)
- ✅ Control FSM (2-cycle state machine)
- ✅ All buffer chains and logic gates

### NOT Synthesized (Open Connections):
- ❌ Memory array (64x64 cells)
- ❌ Sense amplifiers
- ❌ Precharge/Equalization circuits

## 4. Magic Integration Workflow

### Step 1: Generate GDS
```bash
# Push to GitHub → GDS workflow runs
git add .
git commit -m "Prepared for synthesis"
git push
```

### Step 2: Download GDS
After the workflow completes, download:
- `runs/wokwi/results/final/gds/tt_um_example.gds`

### Step 3: Open in Magic
```bash
magic -T sky130A tt_um_example.gds
```

### Step 4: Remove Synthesis Stub
In Magic, locate and **delete** this connection:
```verilog
assign sense_data = 64'h0;  // ← DELETE THIS in Magic
```

This is the dummy connection added to prevent Yosys warnings. It appears as a tie-to-zero cell.

### Step 5: Connect Analog Blocks

**Signals to Connect:**

| Digital Output → | → Analog Input |
|------------------|----------------|
| `wordline[63:0]` | → Memory cell access transistors |
| `bitline[63:0]` | → Memory cell BL |
| `bitline_bar[63:0]` | → Memory cell BL̄ |
| `precharge_en` | → P/EQ control |

| Analog Output → | → Digital Input |
|-----------------|-----------------|
| Sense amp outputs | → `sense_data[63:0]` (delete tie-to-zero first!) |

### Step 6: Manual Routing
- Route metal layers to connect digital ↔ analog
- Verify DRC and LVS
- Export final integrated GDS

## 5. Testing Status

### ✅ Passing Tests:
- **RTL Simulation**: All tests pass (memory stub included)
- **Component Tests**: Row decoder, column decoder, column mux, write drivers
- **Integration Test**: Full SRAM read/write/overwrite operations

### ⏭️ Skipped Tests:
- **Gate-Level Simulation**: Disabled (no memory in digital-only GDS)

### 🔄 Post-Integration Tests:
After Magic integration, you'll need to:
1. Export new GDS with analog blocks
2. Run full-chip LVS
3. Test with analog simulators (SPICE/Xschem)

## 6. Key Files Modified

1. **`src/sram_core.v`**: Added `ifndef SYNTHESIS` conditional
2. **`.github/workflows/gds.yaml`**: Disabled `gl_test` job

## 7. Verification Commands

### Run Local RTL Tests:
```bash
cd test
make clean
make
```

### Check What Gets Synthesized:
After GDS generation, check the synthesis log for:
- Number of cells (should be low, no memory FFs)
- Open inputs/outputs (should list analog connections)

## 8. Important Notes

⚠️ **The `assign sense_data = 64'h0;` is TEMPORARY**
- Only exists to make Yosys happy during synthesis
- Must be removed in Magic before connecting sense amps
- Look for a tie-to-zero cell connected to the sense_data bus

⚠️ **OpenLane automatically defines `SYNTHESIS`**
- No need to modify `config.json`
- The `ifndef SYNTHESIS` will work automatically

⚠️ **Your local tests still work**
- RTL simulation doesn't define `SYNTHESIS`
- Memory stub is included for testing
- All cocotb tests pass as before

## 9. Next Steps

1. ✅ Push to GitHub
2. ✅ Wait for GDS workflow to complete
3. ✅ Download GDS file
4. ✅ Open in Magic
5. ✅ Remove `sense_data` tie-to-zero
6. ✅ Import analog blocks from other groups
7. ✅ Connect digital ↔ analog signals
8. ✅ Run DRC/LVS
9. ✅ Export final integrated GDS

---

**Questions?** Check the synthesis logs in GitHub Actions for detailed information about what was synthesized.

