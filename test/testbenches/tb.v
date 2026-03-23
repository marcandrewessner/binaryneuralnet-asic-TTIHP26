`default_nettype none
`timescale 1ns / 1ps

// Top-level cocotb testbench for tt_um_maw_mnistbnn (MNIST BNN inference engine).
//
// Pin mapping (see project.v / info.yaml):
//   ui_in[7:0]   → data_in[7:0]    8-bit pixel packet input
//   uio_in[0]    → data_in_clk     rising edge strobes each packet
//   uo_out[3:0]  ← number_o        predicted digit 0–9
//   uo_out[4]    ← inference_done  high when result is valid

module tb ();

  initial begin
    $dumpfile("waves/tb.fst");
    $dumpvars(0, tb);
  end

  reg        clk;
  reg        rst_n;
  reg        ena;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  tt_um_maw_mnistbnn user_project (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
  );

endmodule
