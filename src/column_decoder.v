// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module column_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter NUM_COLS = 16
)(
    input  wire [ADDR_WIDTH-1:0] addr,       // 4-bit address input
    input  wire                   enable,     // Enable signal (active high)
    output wire [NUM_COLS-1:0]   col_select  // One-hot column select outputs
);

    // Split address into two 2-bit segments for predecoders
    wire [1:0] addr_low  = addr[1:0];   // Lower 2 bits
    wire [1:0] addr_high = addr[3:2];   // Upper 2 bits

    // Predecoder outputs (4 outputs each)
    wire [3:0] predec_low;   // First 2:4 predecoder
    wire [3:0] predec_high;  // Second 2:4 predecoder

    // Instantiate two 2:4 predecoders
    predecoder_2to4 predec_low_inst (
        .addr(addr_low),
        .enable(enable),
        .out(predec_low)
    );

    predecoder_2to4 predec_high_inst (
        .addr(addr_high),
        .enable(enable),
        .out(predec_high)
    );

    // AND array: Combine predecoder outputs to generate 16 column selects
    // col_select[i] = predec_high[i/4] & predec_low[i%4]
    wire [NUM_COLS-1:0] col_select_unbuffered;
    
    genvar i;
    generate
        for (i = 0; i < NUM_COLS; i = i + 1) begin : and_array
            assign col_select_unbuffered[i] = predec_high[i / 4] & predec_low[i % 4];
        end
    endgenerate

    // Buffer chains for driving column select lines
    generate
        for (i = 0; i < NUM_COLS; i = i + 1) begin : col_drivers
            wordline_driver col_driver (
                .in(col_select_unbuffered[i]),
                .out(col_select[i])
            );
        end
    endgenerate

endmodule

// 2:4 predecoder
// Implements one-hot decoding
module predecoder_2to4 (
    input  wire [1:0] addr,
    input  wire       enable,
    output wire [3:0] out
);

    // Inverted address bits
    wire [1:0] addr_n = ~addr;

    // One-hot decoder implementation
    assign out[0] = enable & addr_n[1] & addr_n[0];  // 00
    assign out[1] = enable & addr_n[1] & addr[0];    // 01
    assign out[2] = enable & addr[1]   & addr_n[0];  // 10
    assign out[3] = enable & addr[1]   & addr[0];    // 11

endmodule

`default_nettype wire

