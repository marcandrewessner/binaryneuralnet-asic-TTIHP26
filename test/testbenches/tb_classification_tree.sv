`default_nettype none
`timescale 1ns / 1ps

// Testbench for classification_tree.
//
// The module is purely combinational — no clock or reset needed.
// Python drives embedding_i; the DUT outputs number_o immediately.

module tb_classification_tree ();

  initial begin
    $dumpfile("waves/tb_classification_tree.fst");
    $dumpvars(0, tb_classification_tree);
  end

  logic [63:0] embedding_i;
  logic  [3:0] number_o;

  classification_tree u_tree (
    .embedding_i (embedding_i),
    .number_o    (number_o)
  );

endmodule
