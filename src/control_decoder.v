// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Control Decoder - Simple 3:8 Decoder for Component Testing
// =============================================================================
//
// Converts 3-bit input to 8-bit one-hot output
// Used for selecting which component to test on-chip
//
// Address mapping:
//   3'b000 → out[0] = 1, others = 0
//   3'b001 → out[1] = 1, others = 0
//   ...
//   3'b111 → out[7] = 1, others = 0

module control_decoder (
    input  wire [2:0] addr,      // 3-bit address input
    input  wire       enable,    // Enable signal (active high)
    output wire [7:0] out        // One-hot outputs
);

    // Inverted address bits for decoder implementation
    wire [2:0] addr_n = ~addr;
    
    // One-hot decoder using AND gates
    // Each output is active when its specific address pattern matches
    assign out[0] = enable & addr_n[2] & addr_n[1] & addr_n[0];  // 000
    assign out[1] = enable & addr_n[2] & addr_n[1] & addr[0];    // 001
    assign out[2] = enable & addr_n[2] & addr[1]   & addr_n[0];  // 010
    assign out[3] = enable & addr_n[2] & addr[1]   & addr[0];    // 011
    assign out[4] = enable & addr[2]   & addr_n[1] & addr_n[0];  // 100
    assign out[5] = enable & addr[2]   & addr_n[1] & addr[0];    // 101
    assign out[6] = enable & addr[2]   & addr[1]   & addr_n[0];  // 110
    assign out[7] = enable & addr[2]   & addr[1]   & addr[0];    // 111

endmodule

`default_nettype wire

