`default_nettype none
`timescale 1ns / 1ps

module tb_mnist_loader ();

  initial begin
    $dumpfile("waves/tb_mnist_loader.fst");
    $dumpvars(0, tb_mnist_loader);
  end

  logic clk;
  logic rst_n;

  // External data interface (driven by cocotb)
  logic       data_in_clk;
  logic [7:0] data_in;

  // done flag back to cocotb
  logic done;

  // Internal SRAM bus (loader drives it; SRAM responds)
  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  mnist_loader loader (
    .clk_i       (clk),
    .rst_ni      (rst_n),
    .sram_req    (sram_req),
    .sram_rsp    (sram_rsp),
    .data_in_clk (data_in_clk),
    .data_in     (data_in),
    .done_o      (done)
  );

  sram_256x8_bm sram (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp)
  );

endmodule
