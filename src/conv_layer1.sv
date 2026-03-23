
// BNN convolution layer 1: 14×14 input (1 ch) → 12×12 output (8 ch)
//
// Input:  SRAM[0..24]   — 14×14 binary image, MSB-first row-major (from mnist_loader)
// Output: SRAM[25..175] — 8 channels × 12×12 binary, channel-first, MSB-first row-major
//                         Channel co occupies bytes [25+co*18 .. 25+co*18+17]
//
// For each output pixel (co, row_out, col_out):
//   1. Load 3×6 window from SRAM at (row_out, col_start) via load_conv_op_3x6
//      One load covers 4 consecutive col positions → col_start ∈ {0, 4, 8}
//   2. XNOR-popcount vs 3×3 kernel for channel co  (conv_weights_3x3_l1)
//   3. Majority vote (popcount ≥ 5 → 1) written as 1 bit to output SRAM
//
// Iteration order (minimises window loads):
//   for row_out ∈ 0..11:
//     for col_start ∈ {0, 4, 8}:          ← one load_conv_op call per window
//       for co ∈ 0..7, write_j ∈ 0..3:    ← 25 SRAM bit-writes
//
// Cycles per window: 1 LOAD_WIN + 8 WAIT_READY + 25 WRITE_BIT + 1 ADVANCE = 42
// Total: 36 windows × 42 ≈ 1512 cycles.

module conv_layer1 (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic start_i,
  output logic done_o,

  output sram_req_t sram_req,
  input  sram_rsp_t sram_rsp
);

  // -----------------------------------------------------------------------
  // Parameters
  // -----------------------------------------------------------------------
  localparam logic [7:0] INPUT_STRIDE = 8'd14;
  localparam logic [7:0] INPUT_PTR    = 8'd0;
  localparam logic [7:0] OUTPUT_BASE  = 8'd25;  // SRAM byte 25..175

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,
    LOAD_WIN,
    WAIT_READY,
    WRITE_BIT,
    ADVANCE,
    DONE
  } state_t;
  state_t state;

  // -----------------------------------------------------------------------
  // Iteration counters
  // -----------------------------------------------------------------------
  logic [3:0] row_out;    // 0..11
  logic [3:0] col_start;  // 0, 4, or 8
  logic [2:0] co;         // output channel 0..7
  logic [1:0] write_j;    // position within col_group 0..3

  // -----------------------------------------------------------------------
  // load_conv_op_3x6 instance
  // -----------------------------------------------------------------------
  logic        loader_read_en;
  logic        loader_ready;
  logic [17:0] loader_buffer;
  sram_req_t   sram_req_load;

  // bit offset into the image for the current window
  logic [7:0] bit_offset;
  assign bit_offset = 8'(row_out) * INPUT_STRIDE + {4'd0, col_start};

  load_conv_op_3x6 u_loader (
    .clk_i             (clk_i),
    .rst_ni            (rst_ni),
    .sram_req          (sram_req_load),
    .sram_rsp          (sram_rsp),
    .read_en_i         (loader_read_en),
    .stride_i          (INPUT_STRIDE),
    .data_pointer_i    (INPUT_PTR),
    .data_bit_offset_i (bit_offset),
    .ready_o           (loader_ready),
    .buffer_o          (loader_buffer)
  );

  // Latch the window buffer the cycle after ready fires
  logic [17:0] buffer_reg;
  always_ff @(posedge clk_i) begin
    if (loader_ready)
      buffer_reg <= loader_buffer;
  end

  // -----------------------------------------------------------------------
  // conv_weights_3x3_l1 instance  (purely combinational)
  //
  // Four separate 5-bit output ports — avoids Icarus packed 2-D array issues.
  // -----------------------------------------------------------------------
  logic [4:0] conv_out0, conv_out1, conv_out2, conv_out3;

  conv_weights_3x3_l1 u_weights (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .select_channel_in  (2'd0),
    .select_channel_out ({1'b0, co}),
    .data_in            (buffer_reg),
    .data_out_0         (conv_out0),
    .data_out_1         (conv_out1),
    .data_out_2         (conv_out2),
    .data_out_3         (conv_out3)
  );

  // -----------------------------------------------------------------------
  // Output address arithmetic
  //
  // Channel-first, MSB-first row-major layout:
  //   linear_idx = co*144 + row_out*12 + col_start + write_j
  //   SRAM byte  = OUTPUT_BASE + linear_idx[10:3]   (÷8)
  //   bit in byte = 7 − linear_idx[2:0]             (MSB first, bit 7 = first pixel)
  // -----------------------------------------------------------------------
  logic [10:0] linear_idx;
  assign linear_idx = ({8'd0, co}     * 11'd144)
                    + ({7'd0, row_out} * 11'd12)
                    + {7'd0, col_start}
                    + {9'd0, write_j};

  logic [7:0] out_byte_addr;
  assign out_byte_addr = OUTPUT_BASE + {3'd0, linear_idx[10:3]};

  logic [2:0] out_bit_pos;
  assign out_bit_pos = 3'd7 - linear_idx[2:0];

  // Select the popcount for the current position, then majority vote (≥5 → 1)
  logic [4:0] conv_sel;
  assign conv_sel = (write_j == 2'd0) ? conv_out0 :
                    (write_j == 2'd1) ? conv_out1 :
                    (write_j == 2'd2) ? conv_out2 :
                                        conv_out3;

  logic maj_bit;
  assign maj_bit = (conv_sel >= 5'd5) ? 1'b1 : 1'b0;

  // -----------------------------------------------------------------------
  // SRAM write request (one bit at a time via byte-mask)
  // -----------------------------------------------------------------------
  sram_req_t sram_req_write;
  always_comb begin
    sram_req_write      = '0;
    sram_req_write.addr = out_byte_addr;
    sram_req_write.bm   = 8'h01 << out_bit_pos;
    sram_req_write.wen  = 1'b1;
    sram_req_write.din  = {7'b0, maj_bit} << out_bit_pos;
  end

  // SRAM mux: writes own the bus during WRITE_BIT; loader drives at all other times
  always_comb begin
    if (state == WRITE_BIT)
      sram_req = sram_req_write;
    else
      sram_req = sram_req_load;
  end

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  assign loader_read_en = (state == LOAD_WIN);
  assign done_o         = (state == DONE);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state     <= IDLE;
      row_out   <= 4'd0;
      col_start <= 4'd0;
      co        <= 3'd0;
      write_j   <= 2'd0;
    end else begin
      case (state)

        IDLE: begin
          if (start_i) begin
            row_out   <= 4'd0;
            col_start <= 4'd0;
            co        <= 3'd0;
            write_j   <= 2'd0;
            state     <= LOAD_WIN;
          end
        end

        // Pulse read_en for one cycle; load_conv_op starts on this edge
        LOAD_WIN: state <= WAIT_READY;

        // Wait for load_conv_op to complete (8 cycles: 7 pipeline + 1 register lag)
        WAIT_READY: begin
          if (loader_ready) begin
            // buffer_reg latches loader_buffer this same posedge (always_ff above)
            co      <= 3'd0;
            write_j <= 2'd0;
            state   <= WRITE_BIT;
          end
        end

        // Write one bit per cycle: cycle through all 8 channels × 4 positions
        WRITE_BIT: begin
          if (write_j == 2'd3) begin
            write_j <= 2'd0;
            if (co == 3'd7) begin
              co    <= 3'd0;
              state <= ADVANCE;
            end else begin
              co <= co + 3'd1;
            end
          end else begin
            write_j <= write_j + 2'd1;
          end
        end

        // Advance to the next (col_start, row_out) window
        ADVANCE: begin
          if (col_start == 4'd8) begin
            col_start <= 4'd0;
            if (row_out == 4'd11)
              state <= DONE;
            else begin
              row_out <= row_out + 4'd1;
              state   <= LOAD_WIN;
            end
          end else begin
            col_start <= col_start + 4'd4;
            state     <= LOAD_WIN;
          end
        end

        DONE: ; // hold until reset or new start

        default: state <= IDLE;
      endcase
    end
  end

endmodule
