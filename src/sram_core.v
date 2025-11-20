// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// SRAM Core - Top-Level Integration
// =============================================================================
//
// 64x64 bit array organized as 1024 words × 4 bits
// 10-bit address: [9:4] = row (64 rows), [3:0] = column (16 words)
//
// Components:
//   - Row Decoder (6:64)
//   - Column Decoder (4:16)
//   - Column Mux (64:4, read path)
//   - Write Drivers (4→64 differential, write path)
//   - Control FSM (2-cycle operation)
//
// External Interfaces:
//   - Memory array (64x64 cells) - provided by other groups
//   - Sense amplifiers (64) - provided by other groups
//   - Precharge/Equalization - provided by other groups

module sram_core (
    input  wire        clk,            // Clock (for memory stub simulation)
    input  wire        rst_n,
    
    // User interface
    input  wire [9:0]  addr,           // 10-bit address
    input  wire [3:0]  data_in,        // 4-bit data input (write)
    input  wire        enable,         // Chip select
    input  wire        read_not_write, // 1=read, 0=write
    output wire [3:0]  data_out,       // 4-bit data output (read)
    output wire        ready           // Operation complete
);

    // ==========================================================================
    // Internal Signals
    // ==========================================================================
    
    // Address decomposition
    wire [5:0] row_addr = addr[9:4];  // Upper 6 bits → row select
    wire [3:0] col_addr = addr[3:0];  // Lower 4 bits → column select
    
    // Control signals from FSM
    wire row_enable;
    wire col_enable;
    wire write_enable;
    wire read_enable;
    wire precharge_enable;
    
    // Decoder outputs
    wire [63:0] row_select;   // One-hot row select
    wire [15:0] col_select;   // One-hot column select
    
    // Memory array interface (internal signals for analog integration)
    // These will be connected to analog blocks manually in Magic layout
    wire [63:0] wordline;       // To memory cells
    
    /* verilator lint_off UNSUPPORTED */
    // Tri-state signals are intentional for analog SRAM interface
    wire [63:0] bitline;        // BL (tri-state from write drivers)
    wire [63:0] bitline_bar;    // BL̄ (tri-state from write drivers)
    /* verilator lint_on UNSUPPORTED */
    
    wire [63:0] sense_data;     // From sense amps
    wire        precharge_en;   // To P/EQ circuit
    
    // ==========================================================================
    // Control FSM
    // ==========================================================================
    
    sram_control ctrl_fsm (
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
    
    // Connect precharge enable to output
    assign precharge_en = precharge_enable;
    
    // ==========================================================================
    // Row Decoder (6:64)
    // ==========================================================================
    
    row_decoder #(
        .ADDR_WIDTH(6),
        .NUM_ROWS(64)
    ) row_dec (
        .addr(row_addr),
        .enable(row_enable),
        .row_select(row_select)
    );
    
    // Connect row_select to wordlines
    assign wordline = row_select;
    
    // ==========================================================================
    // Column Decoder (4:16)
    // ==========================================================================
    
    column_decoder #(
        .ADDR_WIDTH(4),
        .NUM_COLS(16)
    ) col_dec (
        .addr(col_addr),
        .enable(col_enable),
        .col_select(col_select)
    );
    
    // ==========================================================================
    // Column Mux (Read Path: 64→4)
    // ==========================================================================
    
    wire [3:0] mux_out;
    
    column_mux #(
        .WORD_SIZE(4),
        .NUM_WORDS(16),
        .NUM_COLS(64)
    ) col_mux (
        .col_data(sense_data),     // From sense amplifiers
        .col_select(col_select),
        .data_out(mux_out)
    );
    
    // Gate mux output with read_enable
    assign data_out = read_enable ? mux_out : 4'b0;
    
    // ==========================================================================
    // Write Drivers (Write Path: 4→64 differential)
    // ==========================================================================
    
    write_driver #(
        .WORD_SIZE(4),
        .NUM_WORDS(16),
        .NUM_COLS(64)
    ) wr_drv (
        .data_in(data_in),
        .col_select(col_select),
        .write_en(write_enable),
        .bitline(bitline),
        .bitline_bar(bitline_bar)
    );
    
    // ==========================================================================
    // Memory Array Stub (Both Simulation and Synthesis)
    // ==========================================================================
    // This module serves dual purposes:
    // 1. In SIMULATION: Provides functional memory for testing
    // 2. In SYNTHESIS: Creates physical placeholder (~4096 FFs) for layout
    //
    // The stub reserves space and organizes connections (wordlines, bitlines)
    // at predictable locations for easy integration with analog blocks in Magic.
    //
    // ** DELETE THIS MODULE IN MAGIC BEFORE CONNECTING REAL ANALOG ARRAY **
    
    memory_array_stub mem_stub (
        .clk(clk),
        .rst_n(rst_n),
        .wordline(wordline),
        .bitline(bitline),
        .bitline_bar(bitline_bar),
        .sense_data(sense_data),
        .precharge_en(precharge_enable)
    );

endmodule

`default_nettype wire

