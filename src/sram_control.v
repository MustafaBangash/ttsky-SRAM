// SPDX-FileCopyrightText: © 2024 Tiny Tapeout
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// =============================================================================
// SRAM Control FSM - Robust 3-Cycle Design
// =============================================================================
//
// 3-Cycle Operation @ 50MHz (20ns per cycle, 60ns total per operation):
//
// IDLE:
//   Precharge ON, Wordline OFF
//   Ready for new operation
//
// PRECHARGE:
//   Precharge ON, Wordline OFF
//   Bitlines equalize to VDD (~5-10ns needed)
//
// DEVELOP:
//   Precharge OFF, Wordline ON
//   Cells develop ΔV on bitlines (~10-15ns needed)
//   Sense amps NOT active yet - let voltage stabilize
//
// SENSE (for READ) / WRITE:
//   Precharge OFF, Wordline ON
//   READ:  Sense amp fires, data valid at output
//   WRITE: Write drivers active, cells written
//
// This conservative timing ensures reliable operation even with:
//   - Large bitline capacitance
//   - Weak cells
//   - Slow process corners
//
// State Diagram:
//   IDLE ──(enable)──> PRECHARGE ──> DEVELOP ──> SENSE/WRITE ──┐
//     ▲                                            │           │
//     │                    (enable) ───────────────┘           │
//     └─────────────────(!enable)──────────────────────────────┘

module sram_control (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,         // Chip select
    input  wire       read_not_write, // 1=read, 0=write
    
    // Internal control outputs
    output reg        row_enable,     // Enable row decoder (drives wordline)
    output reg        col_enable,     // Enable column decoder
    output reg        write_enable,   // Enable write drivers
    output reg        read_enable,    // Enable sense amps + column mux
    output reg        precharge_enable, // Enable P/EQ (precharge/equalization)
    output reg        ready           // Operation complete
);

    // FSM states (need 2 bits for 4 states)
    localparam IDLE      = 2'b00;
    localparam PRECHARGE = 2'b01;
    localparam DEVELOP   = 2'b10;
    localparam SENSE     = 2'b11;  // Also used for WRITE
    
    reg [1:0] state, next_state;
    
    // Latched read_not_write signal - prevents mid-operation changes
    // from corrupting data by switching between read/write modes
    reg read_not_write_latched;
    
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
    // Latch read_not_write at operation start
    // ==========================================================================
    // Captures the operation type when entering PRECHARGE state.
    // This prevents mid-operation changes from corrupting data.
    // Must capture for both:
    //   - IDLE → PRECHARGE (first operation)
    //   - SENSE → PRECHARGE (back-to-back operations)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_not_write_latched <= 1'b1;  // Default to read (safer)
        end else if (next_state == PRECHARGE) begin
            // Latch when about to enter PRECHARGE (start of any operation)
            read_not_write_latched <= read_not_write;
        end
    end
    
    // ==========================================================================
    // Next State Logic
    // ==========================================================================
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (enable)
                    next_state = PRECHARGE;
                else
                    next_state = IDLE;
            end
            
            PRECHARGE: begin
                next_state = DEVELOP;
            end
            
            DEVELOP: begin
                next_state = SENSE;
            end
            
            SENSE: begin
                if (enable)
                    next_state = PRECHARGE;  // Back-to-back: precharge again
                else
                    next_state = IDLE;       // Done, return to idle
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ==========================================================================
    // Output Logic
    // ==========================================================================
    
    always @(*) begin
        // Default values - everything OFF
        row_enable       = 1'b0;
        col_enable       = 1'b0;
        write_enable     = 1'b0;
        read_enable      = 1'b0;
        precharge_enable = 1'b0;
        ready            = 1'b0;
        
        case (state)
            IDLE: begin
                // Bitlines stay precharged, ready for operation
                precharge_enable = 1'b1;
                ready = 1'b1;
            end
            
            PRECHARGE: begin
                // Precharge ON, wordline OFF
                // Bitlines equalize to VDD, cells disconnected
                precharge_enable = 1'b1;
                col_enable = 1'b1;  // Start column decode (has time to settle)
            end
            
            DEVELOP: begin
                // Precharge OFF, wordline ON
                // Let ΔV develop on bitlines - don't sense yet!
                precharge_enable = 1'b0;
                row_enable = 1'b1;  // Wordline goes HIGH
                col_enable = 1'b1;  // Column already decoded
                // read_enable = 0, write_enable = 0 (wait for voltage to stabilize)
            end
            
            SENSE: begin
                // Precharge OFF, wordline ON, sense/write active
                precharge_enable = 1'b0;
                row_enable = 1'b1;
                col_enable = 1'b1;
                
                // NOW activate read or write path
                // Use LATCHED signal to prevent mid-operation corruption
                if (read_not_write_latched) begin
                    read_enable = 1'b1;   // Sense amp fires, data valid
                end else begin
                    write_enable = 1'b1;  // Write drivers active
                end
                
                ready = 1'b1;  // Operation complete
            end
        endcase
    end

endmodule

`default_nettype wire
