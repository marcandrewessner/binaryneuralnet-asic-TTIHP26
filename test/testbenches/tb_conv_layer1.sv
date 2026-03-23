`default_nettype none
`timescale 1ns / 1ps

// Testbench for conv_layer1.
//
// Phase 1 — MNIST loading:
//   Python streams 98 packets into mnist_loader; SRAM[0..24] fills with the
//   14×14 binary image.  The SRAM mux passes mnist_loader's requests.
//
// Phase 2 — Convolution:
//   Python pulses conv_start.  conv_layer1 reads from SRAM[0..24] and writes
//   the 8×12×12 binary result to SRAM[25..175].

module tb_conv_layer1 ();

  initial begin
    $dumpfile("waves/tb_conv_layer1.fst");
    $dumpvars(0, tb_conv_layer1);
  end

  // -----------------------------------------------------------------------
  // Clock / reset
  // -----------------------------------------------------------------------
  logic clk;
  logic rst_n;

  // -----------------------------------------------------------------------
  // SRAM bus (single port, shared between the two sub-modules)
  // -----------------------------------------------------------------------
  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  sram_req_t sram_req_mnist;
  sram_req_t sram_req_conv;

  logic mnist_done;
  logic conv_start;
  logic conv_done;

  // Hand off bus ownership: mnist_loader until done, then conv_layer1.
  assign sram_req = mnist_done ? sram_req_conv : sram_req_mnist;

  // -----------------------------------------------------------------------
  // mnist_loader — loads the 14×14 image into SRAM[0..24]
  // -----------------------------------------------------------------------
  logic       data_in_clk;
  logic [7:0] data_in;

  mnist_loader u_mnist_loader (
    .clk_i       (clk),
    .rst_ni      (rst_n),
    .sram_req    (sram_req_mnist),
    .sram_rsp    (sram_rsp),
    .data_in_clk (data_in_clk),
    .data_in     (data_in),
    .done_o      (mnist_done)
  );

  // -----------------------------------------------------------------------
  // conv_layer1 — reads SRAM[0..24], writes SRAM[25..175]
  // -----------------------------------------------------------------------
  conv_layer1 u_conv (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .start_i (conv_start),
    .done_o  (conv_done),
    .sram_req(sram_req_conv),
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
