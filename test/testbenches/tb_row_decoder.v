// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the row_decoder module for testing
   with cocotb test_row_decoder.py
*/
module tb_row_decoder ();

    // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("waveforms/tb_row_decoder.vcd");
        $dumpvars(0, tb_row_decoder);
        #1;
    end

    // Wire up the inputs and outputs:
    reg [5:0] addr;
    reg enable;
    wire [63:0] row_select;

    // Instantiate the row decoder
    row_decoder #(
        .ADDR_WIDTH(6),
        .NUM_ROWS(64)
    ) uut (
        .addr(addr),
        .enable(enable),
        .row_select(row_select)
    );

endmodule

`default_nettype wire

