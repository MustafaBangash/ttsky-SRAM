// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Memory Array Stub - Physical Placeholder for Analog Integration
// =============================================================================
//
// This module creates a physical placeholder for the 64×64 memory array that
// will be manually integrated in Magic. It:
//
// 1. Reserves physical space in the GDS (~4096 flip-flops)
// 2. Organizes connections (wordlines, bitlines at predictable locations)
// 3. Prevents optimizer from removing digital logic
// 4. Provides template for analog array drop-in
//
// ** DELETE THIS MODULE IN MAGIC BEFORE CONNECTING REAL ANALOG ARRAY **
//
// This stub is ONLY for:
// - Organizing digital component placement
// - Testing synthesis/precheck
// - Creating a floorplan template
//

module memory_array_stub (
    input  wire        clk,
    input  wire        rst_n,
    
    // Row interface (from row decoder)
    input  wire [63:0] wordline,      // 64 wordline inputs (one per row)
    
    // Column interface (from/to write drivers and column mux)
    input  wire [63:0] bitline,       // 64 bitlines (from write drivers)
    input  wire [63:0] bitline_bar,   // 64 complementary bitlines
    input  wire [15:0] col_select,    // Column select (which 4 bits to write)
    output wire [63:0] sense_data,    // 64 sense outputs (to column mux)
    
    // Control signals (from control FSM)
    input  wire        write_enable,  // Write operation active
    input  wire        precharge_en
);

    // ==========================================================================
    // Memory Array - MINIMAL STUB (64 rows × 4 cols × 4 bits = 1024 bits)
    // ==========================================================================
    // This is a MINIMAL placeholder to keep connections organized.
    // The actual 64×64 analog array will be manually placed in Magic.
    // 
    // This small stub (1024 bits vs 4096 bits = 4x smaller):
    // - Prevents optimization of control logic and drivers
    // - Shows connection organization
    // - Fits within TinyTapeout tile area constraints  
    // - Stores first 4 nibbles (16 bits) per row
    // 
    (* keep = "true" *)
    (* dont_touch = "true" *)
    reg [15:0] memory [0:63];  // 64 rows, each stores 4 nibbles (16 bits)
    
    integer i;
    
    // ==========================================================================
    // Initialization
    // ==========================================================================
    
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 16'h0;
        end
    end
    
    // ==========================================================================
    // Row Selection Logic (One-Hot to Binary)
    // ==========================================================================
    // Convert one-hot wordline to binary row address
    
    function [5:0] encode_wordline;
        input [63:0] wl;
        integer j;
        begin
            encode_wordline = 6'b0;
            for (j = 0; j < 64; j = j + 1) begin
                if (wl[j])
                    encode_wordline = j[5:0];
            end
        end
    endfunction
    
    wire [5:0] active_row;
    assign active_row = encode_wordline(wordline);
    
    // ==========================================================================
    // Write Logic - Updates memory based on bitline values  
    // ==========================================================================
    // Maps all 16 columns to 4 storage slots using modulo 4
    
    reg [3:0] col_index;
    reg [1:0] storage_col;  // Which of 4 slots (col % 4)
    
    always @(*) begin
        // Find which column group is selected (priority encoder)
        col_index = 4'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (col_select[i])
                col_index = i[3:0];
        end
        // Map to one of 4 storage slots
        storage_col = col_index[1:0];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) begin
                memory[i] <= 16'h0;
            end
        end else if (write_enable && |wordline && |col_select) begin
            // Store to mapped column slot (col_index % 4)
            memory[active_row][storage_col*4 +: 4] <= {bitline[col_index*4+3], bitline[col_index*4+2], 
                                                        bitline[col_index*4+1], bitline[col_index*4+0]};
        end
    end
    
    // ==========================================================================
    // Read Logic - Drives sense_data with memory contents
    // ==========================================================================
    // Replicate the 16-bit word across all 4 positions (4 × 16 bits = 64 bits)
    
    assign sense_data = {4{memory[active_row]}};
    
    // ==========================================================================
    // Precharge Monitoring (keeps signal connected)
    // ==========================================================================
    // Monitor control signals to prevent optimization of connections
    
    (* keep = "true" *)
    wire precharge_monitored = precharge_en;
    
    // Monitor complementary bitlines to keep write driver connections
    // (only monitor first 4 bits as representative sample)
    (* keep = "true" *)
    wire [3:0] blb_monitored = bitline_bar[3:0];
    
    // Monitor representative bitlines from rest of array to keep routing
    (* keep = "true" *)
    wire bitline_sample = |bitline[63:4] | |bitline_bar[63:4] | |col_select[15:1] | |wordline[63:4];

endmodule

`default_nettype wire

