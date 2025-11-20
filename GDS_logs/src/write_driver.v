// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module write_driver #(
    parameter WORD_SIZE = 4,      // 4 bits per word
    parameter NUM_WORDS = 16,     // 16 words per row
    parameter NUM_COLS = 64       // 64 total columns
)(
    input  wire [WORD_SIZE-1:0]  data_in,     // 4-bit data to write
    input  wire [NUM_WORDS-1:0]  col_select,  // One-hot word select from column decoder
    input  wire                   write_en,    // Global write enable
    output wire [NUM_COLS-1:0]   bitline,     // 64 bitlines (BL)
    output wire [NUM_COLS-1:0]   bitline_bar  // 64 complementary bitlines (BL̄)
);

    // ==========================================================================
    // Architecture: 64 Differential Write Drivers (one per column)
    // ==========================================================================
    //
    // Each column gets:
    //   - BL  (bitline)
    //   - BL̄ (bitline_bar, complement)
    //
    // Column Organization (Interleaved):
    //   Bit[0]: columns 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60
    //   Bit[1]: columns 1, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 53, 57, 61
    //   Bit[2]: columns 2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62
    //   Bit[3]: columns 3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59, 63
    //
    // Each column's write driver:
    //   - Enabled by: write_en & col_select[word_number]
    //   - Drives: BL = data, BL̄ = ~data (differential)
    //   - Buffer chains for strong drive
    //

    // Unbuffered signals from write control logic
    wire [NUM_COLS-1:0] bitline_unbuffered;
    wire [NUM_COLS-1:0] bitline_bar_unbuffered;

    genvar col;
    generate
        for (col = 0; col < NUM_COLS; col = col + 1) begin : write_drivers
            // Determine which bit position and word this column belongs to
            wire [1:0] bit_position = col % WORD_SIZE;      // 0-3
            wire [3:0] word_number = col / WORD_SIZE;       // 0-15
            
            // This column's write enable
            wire drive_enable = write_en & col_select[word_number];
            
            // Generate differential signals (before buffering)
            // When not enabled, output high-Z (let precharge control bitlines)
            assign bitline_unbuffered[col]     = drive_enable ? data_in[bit_position]  : 1'bz;
            assign bitline_bar_unbuffered[col] = drive_enable ? ~data_in[bit_position] : 1'bz;
            
            // Buffer chains for strong drive (similar to wordline drivers)
            // Drives the actual bitlines with stronger current
            bitline_driver bl_driver (
                .in(bitline_unbuffered[col]),
                .out(bitline[col])
            );
            
            bitline_driver blb_driver (
                .in(bitline_bar_unbuffered[col]),
                .out(bitline_bar[col])
            );
        end
    endgenerate

endmodule

`default_nettype wire

