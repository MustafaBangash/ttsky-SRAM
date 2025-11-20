// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module column_mux #(
    parameter WORD_SIZE = 4,      // 4 bits per word
    parameter NUM_WORDS = 16,     // 16 words per row
    parameter NUM_COLS = 64       // 64 total columns
)(
    input  wire [NUM_COLS-1:0]   col_data,    // Data from all 64 columns (bitlines)
    input  wire [NUM_WORDS-1:0]  col_select,  // One-hot word select from column decoder
    output wire [WORD_SIZE-1:0]  data_out     // Selected 4-bit word
);

    // ==========================================================================
    // Architecture: 4 Parallel 16:1 Muxes (one per bit position)
    // ==========================================================================
    // 
    // Column Organization (Interleaved):
    //   Bit[0]: columns 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60
    //   Bit[1]: columns 1, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 53, 57, 61
    //   Bit[2]: columns 2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62
    //   Bit[3]: columns 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59, 63
    //
    // Each bit position has its own 16:1 mux feeding a sense amplifier
    //

    genvar bit_pos;
    generate
        for (bit_pos = 0; bit_pos < WORD_SIZE; bit_pos = bit_pos + 1) begin : bit_muxes
            // Each bit position has a 16:1 mux
            mux_16to1 mux_inst (
                .col_data(col_data),
                .bit_position(bit_pos),
                .word_select(col_select),
                .data_out(data_out[bit_pos])
            );
        end
    endgenerate

endmodule

// 16:1 Mux for a single bit position
// Selects one column from the 16 columns belonging to this bit position
module mux_16to1 #(
    parameter NUM_WORDS = 16,
    parameter WORD_SIZE = 4
)(
    input  wire [63:0]          col_data,      // All 64 columns
    input  wire [1:0]           bit_position,  // Which bit position (0-3)
    input  wire [NUM_WORDS-1:0] word_select,   // One-hot word select
    output wire                 data_out       // Selected bit
);

    wire [NUM_WORDS-1:0] selected_bits;
    
    genvar word_idx;
    generate
        for (word_idx = 0; word_idx < NUM_WORDS; word_idx = word_idx + 1) begin : word_mux
            // Calculate column index for this word and bit position
            // Column = word_idx * WORD_SIZE + bit_position
            // For bit_pos=0: cols 0, 4, 8, 12, ...
            // For bit_pos=1: cols 1, 5, 9, 13, ...
            wire [5:0] col_idx = word_idx * WORD_SIZE + bit_position;
            
            // Gate the column data with word select
            assign selected_bits[word_idx] = col_data[col_idx] & word_select[word_idx];
        end
    endgenerate
    
    // OR all selected bits together (only one should be active due to one-hot select)
    assign data_out = |selected_bits;

endmodule

`default_nettype wire

