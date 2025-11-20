// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Shared Utility Modules for SRAM
// =============================================================================

// Wordline driver: 2-stage buffer for strong drive (non-inverting)
// Used by row decoder and column decoder
module wordline_driver (
    input  wire in,
    output wire out
);
    // 2-stage inverter chain for strong drive (always synthesized)
    wire inv1;
    assign inv1 = ~in;   // First inverter
    assign out  = ~inv1; // Second inverter (restores polarity)
endmodule

// Bitline driver: 2-stage buffer for strong drive
// Used by write drivers to drive differential bitlines
module bitline_driver (
    input  wire in,
    output wire out
);
    // 2-stage buffer for strong drive (always synthesized)
    wire buf1;
    assign buf1 = in;   // First stage
    assign out  = buf1; // Second stage
endmodule

`default_nettype wire

