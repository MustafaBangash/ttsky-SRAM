// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Shared Utility Modules for SRAM
// =============================================================================
// These buffers drive long analog lines (wordlines, bitlines) that have
// significant capacitive load from SRAM cells. They're implemented as
// 2-stage inverter chains for strong drive capability.
//
// Note: Column select lines do NOT need buffers - they only drive short
// digital wires to the column mux and write driver logic gates.
// =============================================================================

// Wordline driver: 2-stage inverter buffer for strong drive (non-inverting)
// Used by row decoder to drive 64 wordlines (each wordline connects to 64 cells)
module wordline_driver (
    input  wire in,
    output wire out
);
    // 2-stage inverter chain: provides strong drive for long wordlines
    // In real silicon, these would be sized inverters for drive strength
    wire inv1;
    assign inv1 = ~in;   // First inverter
    assign out  = ~inv1; // Second inverter (restores polarity)
endmodule

// Bitline driver: Buffer for write driver outputs
// Used by write drivers to drive differential bitlines (BL/BL̄)
// Each bitline connects to 64 cells and has significant capacitance
// 
// Note: This is a pass-through in RTL because write drivers use tri-state
// outputs (high-Z when not writing). Inverters would break tri-state.
// In real silicon, this would be a tri-state buffer with sized transistors.
module bitline_driver (
    input  wire in,
    output wire out
);
    // Direct pass-through to preserve tri-state behavior
    // In real silicon: sized tri-state buffer for strong drive
    assign out = in;
endmodule

`default_nettype wire

