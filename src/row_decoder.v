// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module row_decoder #(
    parameter ADDR_WIDTH = 6,
    parameter NUM_ROWS = 64
)(
    input  wire [ADDR_WIDTH-1:0] addr,      // 6-bit address input
    input  wire                   enable,    // Enable signal (active high)
    output wire [NUM_ROWS-1:0]   row_select // One-hot row select outputs
);

    // Split address into two 3-bit segments for predecoders
    wire [2:0] addr_low  = addr[2:0];   // Lower 3 bits
    wire [2:0] addr_high = addr[5:3];   // Upper 3 bits

    // Predecoder outputs (8 outputs each)
    wire [7:0] predec_low;   // First 3:8 predecoder
    wire [7:0] predec_high;  // Second 3:8 predecoder

    // Instantiate two 3:8 NOR-based predecoders
    predecoder_3to8 predec_low_inst (
        .addr(addr_low),
        .enable(enable),
        .out(predec_low)
    );

    predecoder_3to8 predec_high_inst (
        .addr(addr_high),
        .enable(enable),
        .out(predec_high)
    );

    // AND array: Combine predecoder outputs to generate 64 row selects
    // row_select[i] = predec_high[i/8] & predec_low[i%8]
    wire [NUM_ROWS-1:0] row_select_unbuffered;
    
    genvar i;
    generate
        for (i = 0; i < NUM_ROWS; i = i + 1) begin : and_array
            assign row_select_unbuffered[i] = predec_high[i / 8] & predec_low[i % 8];
        end
    endgenerate

    // Buffer chains to drive wordlines (3-stage buffer for strong drive)
    generate
        for (i = 0; i < NUM_ROWS; i = i + 1) begin : wordline_drivers
            wordline_driver wl_driver (
                .in(row_select_unbuffered[i]),
                .out(row_select[i])
            );
        end
    endgenerate

endmodule

// Wordline driver: 2-stage inverter chain for strong drive capability
// Even number of inverters maintains signal polarity (non-inverting buffer)
module wordline_driver (
    input  wire in,
    output wire out
);
    wire inv1;
    
    // 2-stage inverter chain (inv -> inv = non-inverting buffer with strong drive)
    assign inv1 = ~in;
    assign out  = ~inv1;

endmodule

// 3:8 NOR-based predecoder
// Implements one-hot decoding using NOR gates
module predecoder_3to8 (
    input  wire [2:0] addr,
    input  wire       enable,
    output wire [7:0] out
);

    // Inverted address bits for NOR implementation
    wire [2:0] addr_n = ~addr;

    // NOR-based decoder implementation
    // Each output is active when its specific address pattern matches
    // Using NOR gates: out[i] = NOR of all mismatching address bits
    
    // For a NOR decoder, we check when address matches by NORing 
    // the complement of matching bits
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

