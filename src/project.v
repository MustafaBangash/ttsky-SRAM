// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Tiny Tapeout SRAM Wrapper
// =============================================================================
//
// Pin Mapping:
//   ui_in[7:0]   : ADDR[7:0]       (Address bits 0-7)
//   uio_in[7:6]  : ADDR[9:8]       (Address bits 8-9)
//   uio_in[5]    : READ_NOT_WRITE  (1=read, 0=write)
//   uio_in[4]    : ENABLE          (Chip select)
//   uio_in[3:0]  : DATA_IN[3:0]    (Write data)
//   uo_out[3:0]  : DATA_OUT[3:0]   (Read data)
//   uo_out[4]    : READY           (Operation complete)
//   uo_out[7:5]  : unused
//
// Memory Array Interface (for integration with analog blocks):
//   - wordline[63:0]       : To memory cells
//   - bitline[63:0]        : Differential bitlines (BL)
//   - bitline_bar[63:0]    : Differential bitlines (BL̄)
//   - sense_data[63:0]     : From sense amplifiers
//
// NOTE: For simulation/testing, memory array interface is stubbed.
//       For tapeout, these signals connect to analog memory array.

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // ==========================================================================
    // Pin Assignments
    // ==========================================================================
    
    wire [9:0] addr;
    wire [3:0] data_in;
    wire       enable;
    wire       read_not_write;
    wire [3:0] data_out;
    wire       ready;
    
    // Input mapping
    assign addr           = {uio_in[7:6], ui_in[7:0]};  // 10-bit address
    assign data_in        = uio_in[3:0];                // 4-bit write data
    assign read_not_write = uio_in[5];                  // Read/write control
    assign enable         = uio_in[4] & ena;            // Chip select (gated with ena)
    
    // Output mapping
    assign uo_out[3:0] = data_out;   // Read data
    assign uo_out[4]   = ready;      // Ready signal
    assign uo_out[7:5] = 3'b0;       // Unused outputs
    
    // Bidirectional pins configured as inputs only
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
    
    // ==========================================================================
    // Memory Array Interface (for analog blocks)
    // ==========================================================================
    
    wire [63:0] wordline;
    wire [63:0] bitline;
    wire [63:0] bitline_bar;
    wire [63:0] sense_data;
    wire        precharge_en;
    
    // For simulation: stub the memory array with a simple behavioral model
    // For tapeout: remove this and connect to actual analog blocks
    sram_array_stub mem_array_stub (
        .clk(clk),
        .wordline(wordline),
        .bitline(bitline),
        .bitline_bar(bitline_bar),
        .sense_data(sense_data),
        .precharge_en(precharge_en)
    );
    
    // ==========================================================================
    // SRAM Core Instance
    // ==========================================================================
    
    sram_core sram (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .data_in(data_in),
        .enable(enable),
        .read_not_write(read_not_write),
        .data_out(data_out),
        .ready(ready),
        .wordline(wordline),
        .bitline(bitline),
        .bitline_bar(bitline_bar),
        .sense_data(sense_data),
        .precharge_en(precharge_en)
    );

endmodule

// =============================================================================
// Memory Array Stub (for simulation only)
// =============================================================================
//
// This is a simple behavioral model of the memory array + sense amps.
// Replace this with actual analog blocks for tapeout.

module sram_array_stub (
    input  wire        clk,
    input  wire [63:0] wordline,
    input  wire [63:0] bitline,
    input  wire [63:0] bitline_bar,
    output wire [63:0] sense_data,
    input  wire        precharge_en  // Precharge enable (for P/EQ circuit)
);

    // Simple register array for simulation
    reg [63:0] memory [0:63];  // 64 rows × 64 bits
    
    integer i;
    initial begin
        // Initialize memory to zero
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 64'h0;
        end
    end
    
    // Find which wordline is active (one-hot encoding)
    reg [5:0] active_row;
    reg row_active;
    
    always @(*) begin
        active_row = 0;
        row_active = 0;
        for (i = 0; i < 64; i = i + 1) begin
            if (wordline[i]) begin
                active_row = i;
                row_active = 1;
            end
        end
    end
    
    // Write operation: if bitline is driven (not Z), write to memory
    always @(posedge clk) begin
        if (row_active) begin
            for (i = 0; i < 64; i = i + 1) begin
                if (bitline[i] !== 1'bz && bitline_bar[i] !== 1'bz) begin
                    // Write operation detected
                    memory[active_row][i] <= bitline[i];
                end
            end
        end
    end
    
    // Read operation: output selected row to sense_data
    assign sense_data = row_active ? memory[active_row] : 64'bz;
    
    // Note: In real implementation, precharge_en controls P/EQ transistors
    // that pull bitlines to VDD. This stub doesn't model that behavior.
    // The analog team will connect precharge_en to their P/EQ circuit.

endmodule

`default_nettype wire
