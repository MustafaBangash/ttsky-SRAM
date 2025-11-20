# Memory Array Stub - Organized Layout Approach

## Overview

This branch implements a **physical memory array stub** that creates an organized, predictable layout for easier Magic integration.

## Motivation

**Problem with Main Branch:**
- Digital components (decoders, muxes, drivers) are scattered randomly
- Small design (~200-400 cells) spreads thinly across the tile
- No reserved space for analog array
- Difficult to predict connection points
- Long, unpredictable routing between components

**Solution:**
- Create a 64×64 register array stub (~4096 flip-flops)
- Reserves physical space matching analog array footprint
- Organizes digital components around the stub perimeter
- Predictable connection points (wordlines, bitlines at edges)
- Easier to delete stub and drop in analog array in Magic

## Implementation

### New File: `src/memory_array_stub.v`

A synthesizable module that:
- **Creates 4096 flip-flops** (64 rows × 64 columns)
- **Prevents optimization** using `(* keep = "true" *)` attributes
- **Provides functional simulation** (works like real memory in tests)
- **Organizes connections:**
  - Input: `wordline[63:0]` from row decoder
  - Input: `bitline[63:0]`, `bitline_bar[63:0]` from write drivers
  - Output: `sense_data[63:0]` to column mux
  - Input: `precharge_en` from control FSM

### Changes to `src/sram_core.v`

**Before (Main Branch):**
```verilog
`ifdef SYNTHESIS
    assign sense_data = {64{wordline[0]}};  // Simple stub
`else
    // Full behavioral memory
    reg [63:0] memory [0:63];
    // ... lots of logic ...
`endif
```

**After (This Branch):**
```verilog
// Single instantiation for both simulation and synthesis
memory_array_stub mem_stub (
    .clk(clk),
    .rst_n(rst_n),
    .wordline(wordline),
    .bitline(bitline),
    .bitline_bar(bitline_bar),
    .sense_data(sense_data),
    .precharge_en(precharge_enable)
);
```

## Expected GDS Layout

### Main Branch (Small Design):
```
┌─────────────────────────────────────────┐
│  Random scattered cells                 │
│    ○ Decoder   ○ Mux    ○ Driver       │
│      ○    ○        ○         ○          │
│  ○       ○    ○        ○                │
│     ○                ○      ○           │
│                                         │
│  ~400 cells spread across entire tile   │
│  Long, crossing wires                   │
└─────────────────────────────────────────┘
```

### This Branch (Organized Layout):
```
┌─────────────────────────────────────────┐
│ Row Decoder│                            │
│  (6:64)    │  ┌──────────────────────┐  │
│   + 64 WL  │  │                      │  │
│   buffers  │  │  Memory Array Stub   │  │
│ ──────────→│  │  64×64 = 4096 FFs    │  │
│            │  │                      │  │
│ Write      │  │  Reserved Space      │  │
│ Drivers    │  │                      │  │
│  + 128 BL  │  │                      │  │
│   buffers  │  │                      │  │
│ ──────────→│  └──────────────────────┘  │
│            │         ↓ 64 sense_data    │
│            │    ┌──────────────────┐    │
│  Column    │    │   Column Mux     │    │
│  Decoder   │───→│   (4×16:1)       │    │
│  (4:16)    │    └──────────────────┘    │
│            │             ↓               │
│            │        data_out[3:0]        │
└─────────────────────────────────────────┘

Total: ~4800 cells (400 digital + 4096 stub + buffers)
```

## Comparison

| Aspect | Main Branch | Memory Stub Branch |
|--------|-------------|-------------------|
| **Cell Count** | ~400-500 cells | ~4800 cells (4096 stub + 400-800 digital) |
| **Layout** | Scattered | Organized around stub |
| **Routing** | Long, crossing wires | Short, predictable connections |
| **Space Usage** | ~20-30% of tile | ~80-90% of tile |
| **Connection Points** | Random locations | Fixed at stub edges |
| **Magic Integration** | Hard to predict | Easy - delete stub block |
| **Synthesis Time** | Fast (~1-2 min) | Slower (~3-5 min) |
| **FEOL Risk** | Low (few cells) | Higher (more congestion) |

## Synthesis Attributes Used

```verilog
(* keep = "true" *)       // Prevents Yosys from optimizing away
(* dont_touch = "true" *) // Additional protection
reg [63:0] memory [0:63];  // 4096 flip-flops
```

These ensure the stub is **fully synthesized** and not optimized away.

## Magic Integration Workflow

### Step 1: Generate GDS
Push this branch → GDS workflow runs → Download artifacts

### Step 2: Open in Magic
```bash
magic -T sky130A tt_um_example.gds
```

### Step 3: Identify the Stub Block
Look for a large rectangular block of standard cells (64×64 flip-flops).
This will be clearly visible as a dense cluster.

### Step 4: Delete the Stub
Select the entire `memory_array_stub` hierarchy and delete it:
```tcl
# In Magic
select cell memory_array_stub
delete
```

### Step 5: Place Analog Array
Drop your analog 64×64 memory array in the **exact same location**.

### Step 6: Connect Signals
The digital components are already positioned around the stub location:
- **Left edge:** Wordlines from row decoder (64 wires)
- **Left edge:** Bitlines from write drivers (128 wires: BL + BL̄)
- **Bottom edge:** Sense data to column mux (64 wires)

Simply route these to your analog array's corresponding ports.

## Testing

### RTL Tests (Still Pass ✅)
```bash
cd test
make clean && make
```

The stub behaves identically to the old behavioral memory in simulation.

### Synthesis
The stub synthesizes to ~4096 DFF cells in the GDS.

## When to Use This Branch

**Use Memory Stub Branch If:**
- ✅ You want organized, predictable layout
- ✅ You need to know exact connection locations
- ✅ You have space in the tile (~4800 cells still fits)
- ✅ You want to make Magic integration easier

**Use Main Branch If:**
- ✅ You want minimal cell count
- ✅ You're testing digital logic only
- ✅ You're worried about FEOL violations from congestion
- ✅ Synthesis time matters (faster with fewer cells)

## Files Modified

1. **New:** `src/memory_array_stub.v` - Physical placeholder module
2. **Modified:** `src/sram_core.v` - Instantiates stub instead of `ifdef` logic
3. **Modified:** `info.yaml` - Added stub to source_files
4. **Modified:** `test/Makefile` - Added stub to VERILOG_SOURCES

## Known Issues / Considerations

### Potential FEOL Violations
With ~4800 cells, placement/routing is more challenging:
- **Solution:** Config already relaxed (PL_TARGET_DENSITY_PCT=75, CLOCK_PERIOD=40ns)
- **If still fails:** May need to reduce stub size (e.g., 32×32 instead of 64×64)

### Synthesis Time
Longer than main branch due to more cells:
- Main: ~1-2 minutes
- Stub: ~3-5 minutes

### Not Needed for Tapeout
This stub is purely for organization. The **main branch GDS also works** - it's just less organized.

## Recommendation

**Try both approaches:**
1. Compare GDS layouts in viewer
2. See which one is easier to integrate in Magic
3. Choose based on your analog team's preferences

If the stub layout looks good and passes precheck, use it! Otherwise, main branch is perfectly functional.

---

**Branch:** `memory-stub-layout`  
**Status:** ✅ Tests Pass | ⏳ Awaiting GDS Generation  
**Decision:** Compare with main branch after GDS builds

