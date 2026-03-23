`default_nettype none
`timescale 1ns / 1ps

// Testbench for maxpool_2x2 configured as layer-1 max-pool.
//
// Setup:  Python pre-loads the SRAM from the conv_layer1 dump
//         (SRAM bytes 0..168 filled with the conv output at 25..168).
// Run:    Python pulses start; maxpool_2x2 reads SRAM[25..168] and writes
//         the 8×6×6 result to SRAM[169..204].
// Check:  Python reads SRAM[169..204] and compares against reference.

module tb_maxpool_layer1 ();

  initial begin
    $dumpfile("waves/tb_maxpool_layer1.fst");
    $dumpvars(0, tb_maxpool_layer1);
  end

  // -----------------------------------------------------------------------
  // Clock / reset
  // -----------------------------------------------------------------------
  logic clk;
  logic rst_n;

  // -----------------------------------------------------------------------
  // Control
  // -----------------------------------------------------------------------
  logic start;
  logic done;

  // -----------------------------------------------------------------------
  // SRAM bus
  // -----------------------------------------------------------------------
  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  // -----------------------------------------------------------------------
  // maxpool_2x2 — layer-1 configuration
  //   8 channels, 12×12 input → 6×6 output
  //   input  at SRAM[25..168]
  //   output at SRAM[169..204]
  // -----------------------------------------------------------------------
  maxpool_2x2 #(
    .NUM_CHANNELS (8),
    .IN_SIZE      (12),
    .INPUT_BASE   (25),
    .OUTPUT_BASE  (169)
  ) u_maxpool (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .start_i (start),
    .done_o  (done),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp)
  );

  // -----------------------------------------------------------------------
  // SRAM — 256 × 8 bit
  // -----------------------------------------------------------------------
  sram_256x8_bm sram (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp)
  );

endmodule
