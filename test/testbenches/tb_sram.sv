`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb_sram ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("waves/tb_sram.fst");
    $dumpvars(0, tb_sram);
  end

  logic clk;
  logic rst_n;

  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  sram_256x8_bm sram (
    .clk_i  (clk),
    .rst_ni (rst_n),
    .sram_req(sram_req),
    .sram_rsp(sram_rsp)
  );

endmodule
