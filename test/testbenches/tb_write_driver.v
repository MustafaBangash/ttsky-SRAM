// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the write_driver module for testing
   with cocotb test_write_driver.py
*/
module tb_write_driver ();

    // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("waveforms/tb_write_driver.vcd");
        $dumpvars(0, tb_write_driver);
        #1;
    end

    // Wire up the inputs and outputs:
    reg [3:0] data_in;        // 4-bit data to write
    reg [15:0] col_select;    // One-hot column select
    reg write_en;             // Write enable
    wire [63:0] bitline;      // 64 bitlines (BL)
    wire [63:0] bitline_bar;  // 64 complementary bitlines (BL̄)

    // Instantiate the write driver
    write_driver #(
        .WORD_SIZE(4),
        .NUM_WORDS(16),
        .NUM_COLS(64)
    ) uut (
        .data_in(data_in),
        .col_select(col_select),
        .write_en(write_en),
        .bitline(bitline),
        .bitline_bar(bitline_bar)
    );

endmodule

`default_nettype wire

