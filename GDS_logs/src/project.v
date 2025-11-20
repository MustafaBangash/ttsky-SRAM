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
//   The memory array interface signals (wordline, bitline, bitline_bar, 
//   sense_data, precharge_en) are kept internal to this module.
//   For tapeout, these will be manually connected to analog blocks in Magic.
//
// NOTE: For simulation/testing, memory array interface is stubbed internally.
//       For tapeout, remove the stub and manually wire to analog cells in layout.

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
    // SRAM Core Instance
    // ==========================================================================
    // Memory array interface is now internal to sram_core
    // For tapeout: Remove memory stub in sram_core and manually connect
    //              to analog blocks in Magic layout
    
    sram_core sram (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .data_in(data_in),
        .enable(enable),
        .read_not_write(read_not_write),
        .data_out(data_out),
        .ready(ready)
    );

endmodule

`default_nettype wire
