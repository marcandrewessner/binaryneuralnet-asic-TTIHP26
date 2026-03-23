
// ============================================
//   DONT TOUCH THIS IS GENERATED! // CODEGEN
// ============================================


// This calculates the data from the weights
// against a 3x6 input signal
// note, that this does directly 4 convolutions with the same weight
// thus it needs to select it then output it.
//
// data_in layout (MSB first):
//   [17:12] = row 0, col 0..5  (bit 17 = row0,col0)
//   [11:6]  = row 1, col 0..5
//   [5:0]   = row 2, col 0..5  (bit 0 = row2,col5)
//
// For sliding position j in 0..3, the 3x3 window uses:
//   row0: data_in[17-j], data_in[16-j], data_in[15-j]
//   row1: data_in[11-j], data_in[10-j], data_in[9-j]
//   row2: data_in[5-j],  data_in[4-j],  data_in[3-j]
//
// Convolution uses XNOR-popcount (BNN: weights/activations in {0,1} ↔ {-1,+1})
// Output data_out[j] = number of matching (weight==activation) pairs in 0..9


module conv_weights_3x3_l2 #(
  localparam NUM_CHANNEL_IN = 8,
  localparam NUM_CHANNEL_OUT = 16,

  localparam int NUM_CHANNEL_IN_W = (NUM_CHANNEL_IN > 1) ? $clog2(NUM_CHANNEL_IN) : 1,
  localparam int NUM_CHANNEL_OUT_W = (NUM_CHANNEL_OUT > 1) ? $clog2(NUM_CHANNEL_OUT) : 1
) (
  input logic clk_i,
  input logic rst_ni,

  input logic [NUM_CHANNEL_IN_W:0] select_channel_in,
  input logic [NUM_CHANNEL_OUT_W:0] select_channel_out,

  // input is a 3x6 1bit window of the input feature
  input logic [17:0] data_in,
  // output is 4 individual 5-bit popcounts for the 4 sliding positions
  // (separate ports instead of packed 2D — Icarus does not handle [3:0][4:0] correctly)
  output logic [4:0] data_out_0,
  output logic [4:0] data_out_1,
  output logic [4:0] data_out_2,
  output logic [4:0] data_out_3
);

  // Selected 3x3 kernel weights (row_col naming: w[row][col], 1-indexed)
  logic w11, w12, w13;
  logic w21, w22, w23;
  logic w31, w32, w33;


  // XNOR-popcount for 4 sliding 3x3 positions
  // data_out_j = count of (weight == activation) pairs, range 0..9
  assign data_out_0 = 5'(!(w11 ^ data_in[17])) + 5'(!(w12 ^ data_in[16])) + 5'(!(w13 ^ data_in[15]))
                    + 5'(!(w21 ^ data_in[11])) + 5'(!(w22 ^ data_in[10])) + 5'(!(w23 ^ data_in[ 9]))
                    + 5'(!(w31 ^ data_in[ 5])) + 5'(!(w32 ^ data_in[ 4])) + 5'(!(w33 ^ data_in[ 3]));
  assign data_out_1 = 5'(!(w11 ^ data_in[16])) + 5'(!(w12 ^ data_in[15])) + 5'(!(w13 ^ data_in[14]))
                    + 5'(!(w21 ^ data_in[10])) + 5'(!(w22 ^ data_in[ 9])) + 5'(!(w23 ^ data_in[ 8]))
                    + 5'(!(w31 ^ data_in[ 4])) + 5'(!(w32 ^ data_in[ 3])) + 5'(!(w33 ^ data_in[ 2]));
  assign data_out_2 = 5'(!(w11 ^ data_in[15])) + 5'(!(w12 ^ data_in[14])) + 5'(!(w13 ^ data_in[13]))
                    + 5'(!(w21 ^ data_in[ 9])) + 5'(!(w22 ^ data_in[ 8])) + 5'(!(w23 ^ data_in[ 7]))
                    + 5'(!(w31 ^ data_in[ 3])) + 5'(!(w32 ^ data_in[ 2])) + 5'(!(w33 ^ data_in[ 1]));
  assign data_out_3 = 5'(!(w11 ^ data_in[14])) + 5'(!(w12 ^ data_in[13])) + 5'(!(w13 ^ data_in[12]))
                    + 5'(!(w21 ^ data_in[ 8])) + 5'(!(w22 ^ data_in[ 7])) + 5'(!(w23 ^ data_in[ 6]))
                    + 5'(!(w31 ^ data_in[ 2])) + 5'(!(w32 ^ data_in[ 1])) + 5'(!(w33 ^ data_in[ 0]));

  // Weight selection: {select_channel_out, select_channel_in} → w11..w33
  always_comb begin
    w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
    w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
    w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;

    case ({select_channel_out, select_channel_in})
      { 5'd0, 4'd0 }: begin  // cout=0, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd0, 4'd1 }: begin  // cout=0, cin=1
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd0, 4'd2 }: begin  // cout=0, cin=2
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd0, 4'd3 }: begin  // cout=0, cin=3
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd0, 4'd4 }: begin  // cout=0, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd0, 4'd5 }: begin  // cout=0, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd0, 4'd6 }: begin  // cout=0, cin=6
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd0, 4'd7 }: begin  // cout=0, cin=7
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd1, 4'd0 }: begin  // cout=1, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd1, 4'd1 }: begin  // cout=1, cin=1
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd1, 4'd2 }: begin  // cout=1, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd1, 4'd3 }: begin  // cout=1, cin=3
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd1, 4'd4 }: begin  // cout=1, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd1, 4'd5 }: begin  // cout=1, cin=5
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd1, 4'd6 }: begin  // cout=1, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd1, 4'd7 }: begin  // cout=1, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd2, 4'd0 }: begin  // cout=2, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd2, 4'd1 }: begin  // cout=2, cin=1
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd2, 4'd2 }: begin  // cout=2, cin=2
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd2, 4'd3 }: begin  // cout=2, cin=3
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd2, 4'd4 }: begin  // cout=2, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd2, 4'd5 }: begin  // cout=2, cin=5
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd2, 4'd6 }: begin  // cout=2, cin=6
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd2, 4'd7 }: begin  // cout=2, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd3, 4'd0 }: begin  // cout=3, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd3, 4'd1 }: begin  // cout=3, cin=1
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd3, 4'd2 }: begin  // cout=3, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd3, 4'd3 }: begin  // cout=3, cin=3
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd3, 4'd4 }: begin  // cout=3, cin=4
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd3, 4'd5 }: begin  // cout=3, cin=5
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd3, 4'd6 }: begin  // cout=3, cin=6
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd3, 4'd7 }: begin  // cout=3, cin=7
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd4, 4'd0 }: begin  // cout=4, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd4, 4'd1 }: begin  // cout=4, cin=1
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd4, 4'd2 }: begin  // cout=4, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd4, 4'd3 }: begin  // cout=4, cin=3
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd4, 4'd4 }: begin  // cout=4, cin=4
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd4, 4'd5 }: begin  // cout=4, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd4, 4'd6 }: begin  // cout=4, cin=6
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd4, 4'd7 }: begin  // cout=4, cin=7
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd5, 4'd0 }: begin  // cout=5, cin=0
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd5, 4'd1 }: begin  // cout=5, cin=1
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd5, 4'd2 }: begin  // cout=5, cin=2
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd5, 4'd3 }: begin  // cout=5, cin=3
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd5, 4'd4 }: begin  // cout=5, cin=4
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd5, 4'd5 }: begin  // cout=5, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd5, 4'd6 }: begin  // cout=5, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd5, 4'd7 }: begin  // cout=5, cin=7
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd6, 4'd0 }: begin  // cout=6, cin=0
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd6, 4'd1 }: begin  // cout=6, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd6, 4'd2 }: begin  // cout=6, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd6, 4'd3 }: begin  // cout=6, cin=3
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd6, 4'd4 }: begin  // cout=6, cin=4
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd6, 4'd5 }: begin  // cout=6, cin=5
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd6, 4'd6 }: begin  // cout=6, cin=6
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd6, 4'd7 }: begin  // cout=6, cin=7
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd7, 4'd0 }: begin  // cout=7, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd7, 4'd1 }: begin  // cout=7, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd7, 4'd2 }: begin  // cout=7, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd7, 4'd3 }: begin  // cout=7, cin=3
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd7, 4'd4 }: begin  // cout=7, cin=4
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd7, 4'd5 }: begin  // cout=7, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd7, 4'd6 }: begin  // cout=7, cin=6
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd7, 4'd7 }: begin  // cout=7, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd8, 4'd0 }: begin  // cout=8, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd8, 4'd1 }: begin  // cout=8, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd8, 4'd2 }: begin  // cout=8, cin=2
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd8, 4'd3 }: begin  // cout=8, cin=3
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd8, 4'd4 }: begin  // cout=8, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd8, 4'd5 }: begin  // cout=8, cin=5
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd8, 4'd6 }: begin  // cout=8, cin=6
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd8, 4'd7 }: begin  // cout=8, cin=7
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd0 }: begin  // cout=9, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd9, 4'd1 }: begin  // cout=9, cin=1
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd2 }: begin  // cout=9, cin=2
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd3 }: begin  // cout=9, cin=3
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd4 }: begin  // cout=9, cin=4
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd9, 4'd5 }: begin  // cout=9, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd6 }: begin  // cout=9, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd9, 4'd7 }: begin  // cout=9, cin=7
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd10, 4'd0 }: begin  // cout=10, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd10, 4'd1 }: begin  // cout=10, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd10, 4'd2 }: begin  // cout=10, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd10, 4'd3 }: begin  // cout=10, cin=3
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd10, 4'd4 }: begin  // cout=10, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd10, 4'd5 }: begin  // cout=10, cin=5
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd10, 4'd6 }: begin  // cout=10, cin=6
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd10, 4'd7 }: begin  // cout=10, cin=7
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd11, 4'd0 }: begin  // cout=11, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd11, 4'd1 }: begin  // cout=11, cin=1
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd11, 4'd2 }: begin  // cout=11, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd11, 4'd3 }: begin  // cout=11, cin=3
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd11, 4'd4 }: begin  // cout=11, cin=4
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd11, 4'd5 }: begin  // cout=11, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd11, 4'd6 }: begin  // cout=11, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd11, 4'd7 }: begin  // cout=11, cin=7
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd12, 4'd0 }: begin  // cout=12, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd12, 4'd1 }: begin  // cout=12, cin=1
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd12, 4'd2 }: begin  // cout=12, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd12, 4'd3 }: begin  // cout=12, cin=3
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd12, 4'd4 }: begin  // cout=12, cin=4
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd12, 4'd5 }: begin  // cout=12, cin=5
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd12, 4'd6 }: begin  // cout=12, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd12, 4'd7 }: begin  // cout=12, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd13, 4'd0 }: begin  // cout=13, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd13, 4'd1 }: begin  // cout=13, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd13, 4'd2 }: begin  // cout=13, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd13, 4'd3 }: begin  // cout=13, cin=3
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd13, 4'd4 }: begin  // cout=13, cin=4
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd13, 4'd5 }: begin  // cout=13, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd13, 4'd6 }: begin  // cout=13, cin=6
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd13, 4'd7 }: begin  // cout=13, cin=7
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd14, 4'd0 }: begin  // cout=14, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd14, 4'd1 }: begin  // cout=14, cin=1
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd14, 4'd2 }: begin  // cout=14, cin=2
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd14, 4'd3 }: begin  // cout=14, cin=3
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd14, 4'd4 }: begin  // cout=14, cin=4
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd14, 4'd5 }: begin  // cout=14, cin=5
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd14, 4'd6 }: begin  // cout=14, cin=6
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 5'd14, 4'd7 }: begin  // cout=14, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd15, 4'd0 }: begin  // cout=15, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd15, 4'd1 }: begin  // cout=15, cin=1
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b1;
      end
      { 5'd15, 4'd2 }: begin  // cout=15, cin=2
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 5'd15, 4'd3 }: begin  // cout=15, cin=3
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd15, 4'd4 }: begin  // cout=15, cin=4
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd15, 4'd5 }: begin  // cout=15, cin=5
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b0;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd15, 4'd6 }: begin  // cout=15, cin=6
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 5'd15, 4'd7 }: begin  // cout=15, cin=7
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      default: begin
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
    endcase
  end

endmodule