`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb_counter4bit ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("waves/tb_counter4bit.fst");
    $dumpvars(0, tb_counter4bit);
    //#1;
  end

  // Wire up the inputs and outputs:
  logic clk;
  logic rst_n;
  logic [3:0] data;

  // Replace tt_um_example with your module name:
  counter4bit counter (
    .clk(clk),
    .rst_n(rst_n),
    .data_out(data)
  );

endmodule
