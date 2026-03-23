
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


module conv_weights_3x3_l1 #(
  localparam NUM_CHANNEL_IN = 1,
  localparam NUM_CHANNEL_OUT = 8,

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
  assign data_out_0 = {4'b0,!(w11^data_in[17])} + {4'b0,!(w12^data_in[16])} + {4'b0,!(w13^data_in[15])}
                    + {4'b0,!(w21^data_in[11])} + {4'b0,!(w22^data_in[10])} + {4'b0,!(w23^data_in[ 9])}
                    + {4'b0,!(w31^data_in[ 5])} + {4'b0,!(w32^data_in[ 4])} + {4'b0,!(w33^data_in[ 3])};
  assign data_out_1 = {4'b0,!(w11^data_in[16])} + {4'b0,!(w12^data_in[15])} + {4'b0,!(w13^data_in[14])}
                    + {4'b0,!(w21^data_in[10])} + {4'b0,!(w22^data_in[ 9])} + {4'b0,!(w23^data_in[ 8])}
                    + {4'b0,!(w31^data_in[ 4])} + {4'b0,!(w32^data_in[ 3])} + {4'b0,!(w33^data_in[ 2])};
  assign data_out_2 = {4'b0,!(w11^data_in[15])} + {4'b0,!(w12^data_in[14])} + {4'b0,!(w13^data_in[13])}
                    + {4'b0,!(w21^data_in[ 9])} + {4'b0,!(w22^data_in[ 8])} + {4'b0,!(w23^data_in[ 7])}
                    + {4'b0,!(w31^data_in[ 3])} + {4'b0,!(w32^data_in[ 2])} + {4'b0,!(w33^data_in[ 1])};
  assign data_out_3 = {4'b0,!(w11^data_in[14])} + {4'b0,!(w12^data_in[13])} + {4'b0,!(w13^data_in[12])}
                    + {4'b0,!(w21^data_in[ 8])} + {4'b0,!(w22^data_in[ 7])} + {4'b0,!(w23^data_in[ 6])}
                    + {4'b0,!(w31^data_in[ 2])} + {4'b0,!(w32^data_in[ 1])} + {4'b0,!(w33^data_in[ 0])};

  // Weight selection: {select_channel_out, select_channel_in} → w11..w33
  always_comb begin
    w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
    w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
    w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;

    case ({select_channel_out, select_channel_in})
      { 4'd0, 2'd0 }: begin  // cout=0, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 4'd1, 2'd0 }: begin  // cout=1, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 4'd2, 2'd0 }: begin  // cout=2, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b1;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
      { 4'd3, 2'd0 }: begin  // cout=3, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 4'd4, 2'd0 }: begin  // cout=4, cin=0
        w11 = 1'b0; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b1;
      end
      { 4'd5, 2'd0 }: begin  // cout=5, cin=0
        w11 = 1'b1; w12 = 1'b1; w13 = 1'b0;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b1; w32 = 1'b1; w33 = 1'b0;
      end
      { 4'd6, 2'd0 }: begin  // cout=6, cin=0
        w11 = 1'b1; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b0; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      { 4'd7, 2'd0 }: begin  // cout=7, cin=0
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b1;
        w21 = 1'b1; w22 = 1'b1; w23 = 1'b1;
        w31 = 1'b0; w32 = 1'b1; w33 = 1'b1;
      end
      default: begin
        w11 = 1'b0; w12 = 1'b0; w13 = 1'b0;
        w21 = 1'b0; w22 = 1'b0; w23 = 1'b0;
        w31 = 1'b0; w32 = 1'b0; w33 = 1'b0;
      end
    endcase
  end

endmodule