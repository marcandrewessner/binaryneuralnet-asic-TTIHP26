`default_nettype none
`timescale 1ns / 1ps

// Testbench for conv_weights_3x3_l1.
//
// The module is purely combinational (w.r.t. the XNOR-popcount outputs).
// The Python test drives select_channel_out, select_channel_in, and data_in,
// then reads back data_out_0..3 and compares against a Python reference.

module tb_conv_weights_3x3_l1 ();

  initial begin
    $dumpfile("waves/tb_conv_weights_3x3_l1.fst");
    $dumpvars(0, tb_conv_weights_3x3_l1);
  end

  // Clock / reset (module is combinational but cocotb needs a clock)
  logic clk;
  logic rst_n;

  // DUT ports
  logic [1:0] select_channel_in;   // NUM_CHANNEL_IN_W+1 = 2 bits  (only value 0 used)
  logic [3:0] select_channel_out;  // NUM_CHANNEL_OUT_W+1 = 4 bits (0..7)
  logic [17:0] data_in;
  logic [4:0]  data_out_0;
  logic [4:0]  data_out_1;
  logic [4:0]  data_out_2;
  logic [4:0]  data_out_3;

  conv_weights_3x3_l1 dut (
    .clk_i              (clk),
    .rst_ni             (rst_n),
    .select_channel_in  (select_channel_in),
    .select_channel_out (select_channel_out),
    .data_in            (data_in),
    .data_out_0         (data_out_0),
    .data_out_1         (data_out_1),
    .data_out_2         (data_out_2),
    .data_out_3         (data_out_3)
  );

endmodule
