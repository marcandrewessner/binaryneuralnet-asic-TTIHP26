`default_nettype none
`timescale 1ns / 1ps

// Full end-to-end inference testbench.
//
// Instantiates main.sv which includes the full pipeline:
//   mnist_loader → conv_layer1 → maxpool_l1 → conv_layer2 →
//   maxpool_l2 → conv_layer3 → classification_tree → number_o
//
// Python drives data_in_clk / data_in and waits for inference_done_o,
// then reads number_o and compares against the Python model prediction.

module tb_main_full ();

  initial begin
    $dumpfile("waves/tb_main_full.fst");
    $dumpvars(0, tb_main_full);
  end

  logic        clk;
  logic        rst_n;
  logic        data_in_clk;
  logic [7:0]  data_in;
  logic [3:0]  number_o;
  logic        inference_done;

  main dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .data_in_clk     (data_in_clk),
    .data_in         (data_in),
    .number_o        (number_o),
    .inference_done_o(inference_done)
  );

endmodule
