// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// SRAM Control FSM
// =============================================================================
//
// 2-Cycle Operation @ 50MHz (20ns per cycle, 40ns total):
//
// READ:
//   Cycle 1: Row decode + precharge (handled by P/EQ)
//   Cycle 2: Sense amplify + column mux → data_out valid
//
// WRITE:
//   Cycle 1: Row decode + column decode
//   Cycle 2: Write drivers active → cells written
//
// FSM States:
//   IDLE   : Waiting for enable
//   CYCLE1 : First cycle (row access)
//   CYCLE2 : Second cycle (column access)
//
// Timing:
//   - All transitions on rising edge only
//   - READY signal indicates operation complete
//   - New operation can start after READY

module sram_control (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,        // Chip select
    input  wire       read_not_write, // 1=read, 0=write
    
    // Internal control outputs
    output reg        row_enable,     // Enable row decoder
    output reg        col_enable,     // Enable column decoder
    output reg        write_enable,   // Enable write drivers
    output reg        read_enable,    // Enable column mux (read path)
    output reg        precharge_enable, // Enable P/EQ (precharge/equalization)
    output reg        ready           // Operation complete
);

    // FSM states
    localparam IDLE   = 2'b00;
    localparam CYCLE1 = 2'b01;
    localparam CYCLE2 = 2'b10;
    
    reg [1:0] state, next_state;
    
    // ==========================================================================
    // State Register
    // ==========================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // ==========================================================================
    // Next State Logic
    // ==========================================================================
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (enable)
                    next_state = CYCLE1;
                else
                    next_state = IDLE;
            end
            
            CYCLE1: begin
                next_state = CYCLE2;
            end
            
            CYCLE2: begin
                if (enable)
                    next_state = CYCLE1;  // Back-to-back operations
                else
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ==========================================================================
    // Output Logic
    // ==========================================================================
    
    always @(*) begin
        // Default values
        row_enable       = 1'b0;
        col_enable       = 1'b0;
        write_enable     = 1'b0;
        read_enable      = 1'b0;
        precharge_enable = 1'b0;
        ready            = 1'b0;
        
        case (state)
            IDLE: begin
                precharge_enable = 1'b1;  // Precharge bitlines when idle
                ready = 1'b1;             // Ready for new operation
            end
            
            CYCLE1: begin
                precharge_enable = 1'b1;  // Precharge during first half of cycle
                // Activate row decoder (both read and write)
                row_enable = 1'b1;
                col_enable = 1'b1;  // Decode column address too
            end
            
            CYCLE2: begin
                precharge_enable = 1'b0;  // Turn off precharge for sensing/writing
                // Keep row/col active
                row_enable = 1'b1;
                col_enable = 1'b1;
                
                // Activate read or write path
                if (read_not_write) begin
                    read_enable = 1'b1;   // Column mux active
                end else begin
                    write_enable = 1'b1;  // Write drivers active
                end
                
                ready = 1'b1;  // Data valid at end of CYCLE2
            end
        endcase
    end

endmodule

`default_nettype wire

