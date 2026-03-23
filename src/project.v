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

  wire [3:0] number_o;
  wire       inference_done_o;

  assign uo_out  = {3'b000, inference_done_o, number_o};
  assign uio_oe  = 8'h00;   // all bidirectional pins are inputs
  assign uio_out = 8'h00;

  // SRAM interface wires (macro instantiated here so instance name is 'sram' at top level)
  wire [7:0] sram_addr, sram_bm, sram_din, sram_dout;
  wire       sram_wen, sram_ren;

  main m (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .data_in_clk     (uio_in[0]),
    .data_in         (ui_in),
    .number_o        (number_o),
    .inference_done_o(inference_done_o),
    .sram_addr_o     (sram_addr),
    .sram_bm_o       (sram_bm),
    .sram_wen_o      (sram_wen),
    .sram_ren_o      (sram_ren),
    .sram_din_o      (sram_din),
    .sram_dout_i     (sram_dout)
  );

  RM_IHPSG13_1P_256x8_c3_bm_bist sram (
    .A_CLK (clk),
    .A_MEN (rst_n),
    .A_WEN (sram_wen),
    .A_REN (sram_ren),
    .A_ADDR(sram_addr),
    .A_DIN (sram_din),
    .A_DLY (1'b1),
    .A_DOUT(sram_dout),
    .A_BM  (sram_bm),
    .A_BIST_EN  (1'b0),
    .A_BIST_CLK (1'b0),
    .A_BIST_MEN (1'b0),
    .A_BIST_REN (1'b0),
    .A_BIST_WEN (1'b0),
    .A_BIST_ADDR(8'h00),
    .A_BIST_DIN (8'h00),
    .A_BIST_BM  (8'h00)
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:1]};

endmodule
