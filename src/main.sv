
// This block defines the entry point module

module main (
  input logic clk_i,
  input logic rst_ni,

  input logic data_in_clk,
  input logic [7:0] data_in,
);
  

  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  sram_256x8_bm sram (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp),
  )

  mnist_loader mnist_loader (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp),
    .data_in_clk(data_in_clk),
    .data_in(data_in),
  );

endmodule