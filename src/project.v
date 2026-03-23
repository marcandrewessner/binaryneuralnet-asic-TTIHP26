/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_maw_mnistbnn (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uo_out  = 0;
  assign uio_oe  = 0;
  assign uio_out = 0;

  main m (
    .clk_i(clk),
    .rst_ni(rst_n),
    .data_in_clk(uio_in[0]),
    .data_in(ui_in)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena};

endmodule
