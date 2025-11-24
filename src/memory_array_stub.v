// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// Memory Array Stub - Lightweight Physical Placeholder
// =============================================================================
//
// This module creates a LIGHTWEIGHT physical placeholder using simple logic
// instead of expensive flip-flops. It serves to:
//
// 1. Reserve physical space in the GDS (using buffers, not flip-flops)
// 2. Organize connections at predictable locations  
// 3. Prevent optimizer from removing peripheral logic
// 4. Provide a template for analog array integration in Magic
//
// ** Key Design Choice: Uses buffers/simple gates instead of registers **
//    - Flip-flops: ~8 transistors each → expensive
//    - Buffers: ~2 transistors each → 4x cheaper
//    - Dummy logic: minimal area but reserves space
//

module memory_array_stub (
    input  wire        clk,
    input  wire        rst_n,
    
    // Row interface (from row decoder)
    input  wire [63:0] wordline,
    
    // Column interface (from/to write drivers and column mux)
    input  wire [63:0] bitline,
    input  wire [63:0] bitline_bar,
    input  wire [15:0] col_select,
    output wire [63:0] sense_data,
    
    // Control signals (from control FSM)
    input  wire        write_enable,
    input  wire        precharge_en
);

    `ifndef SYNTHESIS
        // ==========================================================================
        // SIMULATION: Full Functional Memory (1024 bits)
        // ==========================================================================
        
        reg [15:0] memory [0:63];
        integer i;
        
        initial begin
            for (i = 0; i < 64; i = i + 1) begin
                memory[i] = 16'h0;
            end
        end
        
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
        
        function [3:0] encode_colselect;
            input [15:0] cs;
            integer j;
            begin
                encode_colselect = 4'd0;
                for (j = 0; j < 16; j = j + 1) begin
                    if (cs[j])
                        encode_colselect = j[3:0];
                end
            end
        endfunction
        
        wire [5:0] active_row = encode_wordline(wordline);
        wire [3:0] col_index = encode_colselect(col_select);
        wire [1:0] storage_slot = col_index[1:0];
        
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                for (i = 0; i < 64; i = i + 1) begin
                    memory[i] <= 16'h0;
                end
            end else if (write_enable && |wordline && |col_select) begin
                memory[active_row][storage_slot*4 +: 4] <= {bitline[col_index*4+3], bitline[col_index*4+2], 
                                                             bitline[col_index*4+1], bitline[col_index*4+0]};
            end
        end
        
        assign sense_data = {4{memory[active_row]}};
        
    `else
        // ==========================================================================
        // SYNTHESIS: Lightweight Dummy Array (buffers/simple gates)
        // ==========================================================================
        // Create a grid of cheap cells that reserve space but don't need flip-flops
        // Strategy: Use combinational logic with keep attributes
        
        genvar row, col;
        
        // Create 64×16 = 1024 dummy buffer chains
        // Each "cell" is just a few buffers to create physical presence
        wire [63:0] dummy_cell [0:15];
        
        generate
            for (row = 0; row < 64; row = row + 1) begin : row_gen
                for (col = 0; col < 16; col = col + 1) begin : col_gen
                    // Dummy cell: AND the wordline with bitline and column select
                    // This creates a small physical gate tied to all connections
                    (* keep = "true" *)
                    wire cell_input;
                    
                    assign cell_input = wordline[row] & 
                                       bitline[col*4] & 
                                       col_select[col] & 
                                       write_enable;
                    
                    // Buffer the signal to create physical area
                    (* keep = "true" *)
                    wire cell_buf1, cell_buf2;
                    
                    assign cell_buf1 = cell_input;
                    assign cell_buf2 = cell_buf1;
                    assign dummy_cell[col][row] = cell_buf2;
                end
            end
        endgenerate
        
        // Output: OR together dummy cells to create sense data
        // This ensures the entire chain stays connected
        wire [15:0] col_outputs;
        generate
            for (col = 0; col < 16; col = col + 1) begin : output_gen
                assign col_outputs[col] = |dummy_cell[col];
            end
        endgenerate
        
        // Replicate to fill 64-bit output
        assign sense_data = {4{col_outputs}};
        
        // Tie unused signals to prevent optimization
        wire unused = precharge_en & |bitline_bar & rst_n & clk;
        
    `endif

endmodule

`default_nettype wire
