// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the column_decoder module for testing
   with cocotb test_column_decoder.py
*/
module tb_column_decoder ();

    // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_column_decoder);
        #1;
    end

    // Wire up the inputs and outputs:
    reg [3:0] addr;
    reg enable;
    wire [15:0] col_select;

    // Instantiate the column decoder
    column_decoder #(
        .ADDR_WIDTH(4),
        .NUM_COLS(16)
    ) uut (
        .addr(addr),
        .enable(enable),
        .col_select(col_select)
    );

endmodule

`default_nettype wire

