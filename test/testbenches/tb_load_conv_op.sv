`default_nettype none
`timescale 1ns / 1ps

module tb_load_conv_op ();

  initial begin
    $dumpfile("waves/tb_load_conv_op.fst");
    $dumpvars(0, tb_load_conv_op);
  end

  logic clk;
  logic rst_n;

  // SRAM bus (load_conv_op drives reads; SRAM responds)
  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  // load_conv_op control / status
  logic        read_en;
  logic [7:0]  stride;
  logic [7:0]  data_pointer;
  logic [7:0]  data_bit_offset;
  logic        ready;
  logic [17:0] buffer;

  load_conv_op dut (
    .clk_i             (clk),
    .rst_ni            (rst_n),
    .sram_req          (sram_req),
    .sram_rsp          (sram_rsp),
    .read_en_i         (read_en),
    .stride_i          (stride),
    .data_pointer_i    (data_pointer),
    .data_bit_offset_i (data_bit_offset),
    .ready_o           (ready),
    .buffer_o          (buffer)
  );

  sram_256x8_bm sram (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp)
  );

endmodule
