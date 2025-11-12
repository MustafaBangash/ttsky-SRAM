// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the column_mux module for testing
   with cocotb test_column_mux.py
*/
module tb_column_mux ();

    // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("waveforms/tb_column_mux.vcd");
        $dumpvars(0, tb_column_mux);
        #1;
    end

    // Wire up the inputs and outputs:
    reg [63:0] col_data;      // Data from all 64 columns
    reg [15:0] col_select;    // One-hot column select
    wire [3:0] data_out;      // Selected 4-bit word

    // Instantiate the column mux
    column_mux #(
        .WORD_SIZE(4),
        .NUM_WORDS(16),
        .NUM_COLS(64)
    ) uut (
        .col_data(col_data),
        .col_select(col_select),
        .data_out(data_out)
    );

endmodule

`default_nettype wire

