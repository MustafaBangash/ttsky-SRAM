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
    wire [63:0] bitline;        // BL
    wire [63:0] bitline_bar;    // BL̄
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
    
`ifndef SYNTHESIS
    // ==========================================================================
    // Memory Array Stub (SIMULATION ONLY - for RTL testing)
    // ==========================================================================
    // ⚠️ This stub is removed during synthesis. In the final chip, sense_data
    // will be connected to analog sense amplifiers in Magic layout.
    
    // Simple behavioral memory for simulation
    reg [63:0] memory [0:63];
    integer i;
    
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 64'h0;
        end
    end
    
    // One-hot to binary decoder (priority-encoded for synthesis)
    reg [5:0] active_row;
    always @(*) begin
        active_row = 6'b0;
        // Priority encoder - check from LSB to MSB
        if (wordline[0])  active_row = 6'd0;
        if (wordline[1])  active_row = 6'd1;
        if (wordline[2])  active_row = 6'd2;
        if (wordline[3])  active_row = 6'd3;
        if (wordline[4])  active_row = 6'd4;
        if (wordline[5])  active_row = 6'd5;
        if (wordline[6])  active_row = 6'd6;
        if (wordline[7])  active_row = 6'd7;
        if (wordline[8])  active_row = 6'd8;
        if (wordline[9])  active_row = 6'd9;
        if (wordline[10]) active_row = 6'd10;
        if (wordline[11]) active_row = 6'd11;
        if (wordline[12]) active_row = 6'd12;
        if (wordline[13]) active_row = 6'd13;
        if (wordline[14]) active_row = 6'd14;
        if (wordline[15]) active_row = 6'd15;
        if (wordline[16]) active_row = 6'd16;
        if (wordline[17]) active_row = 6'd17;
        if (wordline[18]) active_row = 6'd18;
        if (wordline[19]) active_row = 6'd19;
        if (wordline[20]) active_row = 6'd20;
        if (wordline[21]) active_row = 6'd21;
        if (wordline[22]) active_row = 6'd22;
        if (wordline[23]) active_row = 6'd23;
        if (wordline[24]) active_row = 6'd24;
        if (wordline[25]) active_row = 6'd25;
        if (wordline[26]) active_row = 6'd26;
        if (wordline[27]) active_row = 6'd27;
        if (wordline[28]) active_row = 6'd28;
        if (wordline[29]) active_row = 6'd29;
        if (wordline[30]) active_row = 6'd30;
        if (wordline[31]) active_row = 6'd31;
        if (wordline[32]) active_row = 6'd32;
        if (wordline[33]) active_row = 6'd33;
        if (wordline[34]) active_row = 6'd34;
        if (wordline[35]) active_row = 6'd35;
        if (wordline[36]) active_row = 6'd36;
        if (wordline[37]) active_row = 6'd37;
        if (wordline[38]) active_row = 6'd38;
        if (wordline[39]) active_row = 6'd39;
        if (wordline[40]) active_row = 6'd40;
        if (wordline[41]) active_row = 6'd41;
        if (wordline[42]) active_row = 6'd42;
        if (wordline[43]) active_row = 6'd43;
        if (wordline[44]) active_row = 6'd44;
        if (wordline[45]) active_row = 6'd45;
        if (wordline[46]) active_row = 6'd46;
        if (wordline[47]) active_row = 6'd47;
        if (wordline[48]) active_row = 6'd48;
        if (wordline[49]) active_row = 6'd49;
        if (wordline[50]) active_row = 6'd50;
        if (wordline[51]) active_row = 6'd51;
        if (wordline[52]) active_row = 6'd52;
        if (wordline[53]) active_row = 6'd53;
        if (wordline[54]) active_row = 6'd54;
        if (wordline[55]) active_row = 6'd55;
        if (wordline[56]) active_row = 6'd56;
        if (wordline[57]) active_row = 6'd57;
        if (wordline[58]) active_row = 6'd58;
        if (wordline[59]) active_row = 6'd59;
        if (wordline[60]) active_row = 6'd60;
        if (wordline[61]) active_row = 6'd61;
        if (wordline[62]) active_row = 6'd62;
        if (wordline[63]) active_row = 6'd63;
    end
    
    // Write operation (only write bits that are driven, ignore high-Z)
    always @(posedge clk) begin
        if (write_enable) begin
            for (i = 0; i < 64; i = i + 1) begin
                // Only write if bitline is actually driven (not high-Z)
                if (bitline[i] !== 1'bz) begin
                    memory[active_row][i] <= bitline[i];
                end
            end
        end
    end
    
    // Read operation (always driven - synthesis safe)
    assign sense_data = memory[active_row];
    assign precharge_en = precharge_enable;

`else
    // ==========================================================================
    // Synthesis Mode: No memory array (analog blocks added in Magic)
    // ==========================================================================
    // Create a stub that prevents optimization but uses minimal logic.
    // Make sense_data depend on wordline so the read path isn't optimized away.
    // In Magic, delete this stub and connect to real sense amps.
    assign sense_data = {64{wordline[0]}};  // Simple stub that keeps logic alive
    assign precharge_en = precharge_enable;
`endif

endmodule

`default_nettype wire

