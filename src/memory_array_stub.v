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
    output wire [63:0] sense_data,    // 64 sense outputs (to column mux)
    
    // Precharge control (from control FSM)
    input  wire        precharge_en
);

    // ==========================================================================
    // Memory Array - 64 rows × 64 columns = 4096 bits
    // ==========================================================================
    // This creates a physical block of flip-flops that reserves space
    // Use synthesis attributes to prevent optimization
    
    (* keep = "true" *)
    (* dont_touch = "true" *)
    reg [63:0] memory [0:63];
    
    integer i;
    
    // ==========================================================================
    // Initialization
    // ==========================================================================
    
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 64'h0;
        end
    end
    
    // ==========================================================================
    // Row Selection Logic (One-Hot to Binary)
    // ==========================================================================
    // Decode which row is active based on wordline
    
    reg [5:0] active_row;
    
    always @(*) begin
        active_row = 6'b0;
        // Priority encoder
        for (i = 0; i < 64; i = i + 1) begin
            if (wordline[i])
                active_row = i[5:0];
        end
    end
    
    // ==========================================================================
    // Write Logic - Updates memory based on bitline values
    // ==========================================================================
    // Only writes if bitline is driven (not high-Z)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) begin
                memory[i] <= 64'h0;
            end
        end else begin
            // Write to active row
            for (i = 0; i < 64; i = i + 1) begin
                if (bitline[i] !== 1'bz && wordline[active_row]) begin
                    memory[active_row][i] <= bitline[i];
                end
            end
        end
    end
    
    // ==========================================================================
    // Read Logic - Drives sense_data with memory contents
    // ==========================================================================
    // Always drive output (no high-Z) to prevent optimization
    
    assign sense_data = memory[active_row];
    
    // ==========================================================================
    // Precharge Monitoring (keeps signal connected)
    // ==========================================================================
    // Even though we don't functionally use precharge_en in this stub,
    // we need to reference it so the connection isn't optimized away
    
    (* keep = "true" *)
    wire precharge_monitored = precharge_en;
    
    // Tie unused complementary bitlines into the logic to prevent optimization
    // This ensures all 128 bitline connections are preserved
    (* keep = "true" *)
    wire [63:0] blb_monitored = bitline_bar;

endmodule

`default_nettype wire

