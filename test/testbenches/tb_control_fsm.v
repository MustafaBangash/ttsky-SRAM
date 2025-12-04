`default_nettype none
`timescale 1ns / 1ps

// Testbench wrapper for SRAM Control FSM
// Run with: make MODULE=tb_control_fsm TESTCASE=test_control_fsm_waveforms

module tb_control_fsm ();

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Inputs
    reg enable;
    reg read_not_write;
    
    // Outputs
    wire row_enable;
    wire col_enable;
    wire write_enable;
    wire read_enable;
    wire precharge_enable;
    wire ready;
    
    // Internal state (for waveform visibility)
    wire [1:0] state;

    // Instantiate DUT
    sram_control dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .read_not_write(read_not_write),
        .row_enable(row_enable),
        .col_enable(col_enable),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .precharge_enable(precharge_enable),
        .ready(ready)
    );
    
    // Expose internal state for waveform viewing
    assign state = dut.state;

    // Dump waveforms
    initial begin
        $dumpfile("waveforms/tb_control_fsm.vcd");
        $dumpvars(0, tb_control_fsm);
        
        // Also dump internal state explicitly
        $dumpvars(1, dut.state);
        $dumpvars(1, dut.next_state);
    end

endmodule

`default_nettype wire

