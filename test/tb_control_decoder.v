`default_nettype none
`timescale 1ns / 1ps

module tb_control_decoder ();

    // Testbench signals
    reg [2:0] addr;
    reg enable;
    wire [7:0] out;

    // Instantiate DUT
    control_decoder dut (
        .addr(addr),
        .enable(enable),
        .out(out)
    );

    // Dump waves
    initial begin
        $dumpfile("tb_control_decoder.vcd");
        $dumpvars(0, tb_control_decoder);
    end

endmodule

