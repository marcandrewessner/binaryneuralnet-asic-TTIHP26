
// BNN convolution layer 2: 6×6 input (8 ch) → 4×4 output (16 ch)
//
// Input:  SRAM[169..204]  — 8 channels × 6×6 binary, channel-first MSB-first row-major
//                           Channel ci occupies bits [ci*36 .. ci*36+35]
//                           Byte = 169 + linear_bit/8, bit = 7 - linear_bit%8
// Output: SRAM[205..236]  — 16 channels × 4×4 binary, same layout
//                           Channel co occupies bytes [205+co*2 .. 205+co*2+1]
//
// Kernel: 3×3, stride 1, XNOR-popcount over 8 input channels
// Threshold: popcount >= 37 (N=72=8×9, majority > 36)
//
// For each (row_out in 0..3):
//   Load 8 windows (one per input channel ci), accumulate into acc[co][j] for all co=0..15
//   After all 8 channels: write 64 output bits (16 co × 4 column positions)
//
// The 3×6 window for channel ci, row_out always starts at col 0:
//   data_pointer_i  = 169 + (ci*36 + row_out*6) / 8
//   data_bit_offset = (ci*36 + row_out*6) % 8
//   stride_i        = 6
//
// Cycles per row: 8*(1 LOAD_WIN + 8 WAIT + 1 ADVANCE_CI + 16 ACCUM_CO) + 64 WRITE ≈ 272
// Total: 4 rows × 272 ≈ 1088 cycles.

module conv_layer2 (
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
  localparam int IN_CHANNELS  = 8;
  localparam int OUT_CHANNELS = 16;
  localparam int IN_CH_BITS   = 36;   // 6×6 per channel
  localparam int OUT_CH_SZ    = 16;   // 4×4 per output channel
  localparam int THRESHOLD    = 37;   // 8*9/2 + 1

  localparam logic [7:0] INPUT_BASE   = 8'd169;
  localparam logic [7:0] INPUT_STRIDE = 8'd6;
  localparam logic [7:0] OUTPUT_BASE  = 8'd205;

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,
    LOAD_WIN,
    WAIT_READY,
    ACCUM_CO,
    ADVANCE_CI,
    WRITE_BIT,
    DONE
  } state_t;
  state_t state;

  // -----------------------------------------------------------------------
  // Iteration counters
  // -----------------------------------------------------------------------
  logic [1:0] row_out;  // 0..3
  logic [2:0] ci;       // 0..7  input channel (inner loop for accumulation)
  logic [3:0] co;       // 0..15 output channel
  logic [1:0] write_j;  // 0..3  write position within row

  // -----------------------------------------------------------------------
  // Accumulators: 16 output channels × 4 sliding positions × 7 bits
  // -----------------------------------------------------------------------
  logic [6:0] acc [0:15][0:3];

  // -----------------------------------------------------------------------
  // load_conv_op_3x6 instance
  // -----------------------------------------------------------------------
  logic        loader_read_en;
  logic        loader_ready;
  logic [17:0] loader_buffer;
  sram_req_t   sram_req_load;

  // Address calculation: byte-align starting bit = ci*36 + row_out*6
  logic [8:0] base_bit;
  assign base_bit = {6'b0, ci} * 9'd36 + {7'b0, row_out} * 9'd6;

  logic [7:0] load_ptr;
  logic [7:0] load_bit_off;
  assign load_ptr    = INPUT_BASE + {1'b0, base_bit[8:3]};    // base_bit / 8
  assign load_bit_off = {5'b0, base_bit[2:0]};               // base_bit % 8 (0..7)

  load_conv_op_3x6 u_loader (
    .clk_i             (clk_i),
    .rst_ni            (rst_ni),
    .sram_req          (sram_req_load),
    .sram_rsp          (sram_rsp),
    .read_en_i         (loader_read_en),
    .stride_i          (INPUT_STRIDE),
    .data_pointer_i    (load_ptr),
    .data_bit_offset_i (load_bit_off),
    .ready_o           (loader_ready),
    .buffer_o          (loader_buffer)
  );

  // Latch window buffer the cycle after ready fires (matches conv_layer1 pattern)
  logic [17:0] buffer_reg;
  always_ff @(posedge clk_i) begin
    if (loader_ready)
      buffer_reg <= loader_buffer;
  end

  // -----------------------------------------------------------------------
  // conv_weights_3x3_l2 — purely combinational
  //   select_channel_in  = ci   (3-bit + 1 pad = 4 bits)
  //   select_channel_out = co   (4-bit + 1 pad = 5 bits)
  // -----------------------------------------------------------------------
  logic [4:0] conv_out0, conv_out1, conv_out2, conv_out3;

  conv_weights_3x3_l2 u_weights (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .select_channel_in  ({1'b0, ci}),       // 4 bits [3:0]
    .select_channel_out ({1'b0, co}),       // 5 bits [4:0]
    .data_in            (buffer_reg),
    .data_out_0         (conv_out0),
    .data_out_1         (conv_out1),
    .data_out_2         (conv_out2),
    .data_out_3         (conv_out3)
  );

  // -----------------------------------------------------------------------
  // Output address arithmetic
  //
  // Channel-first, MSB-first row-major:
  //   linear_idx = co * OUT_CH_SZ + row_out * 4 + write_j
  //              = co * 16        + row_out * 4 + write_j   (max 255, 8 bits)
  //   byte  = OUTPUT_BASE + linear_idx[7:3]
  //   bit   = 7 - linear_idx[2:0]
  // -----------------------------------------------------------------------
  logic [7:0] linear_idx;
  assign linear_idx = ({4'd0, co}     * 8'd16)
                    + ({6'd0, row_out} * 8'd4)
                    + {6'd0, write_j};

  logic [7:0] out_byte_addr;
  assign out_byte_addr = OUTPUT_BASE + {3'd0, linear_idx[7:3]};

  logic [2:0] out_bit_pos;
  assign out_bit_pos = 3'd7 - linear_idx[2:0];

  // Select accumulated value and apply threshold
  logic [6:0] acc_sel;
  assign acc_sel = (write_j == 2'd0) ? acc[co][0] :
                   (write_j == 2'd1) ? acc[co][1] :
                   (write_j == 2'd2) ? acc[co][2] :
                                       acc[co][3];

  logic maj_bit;
  assign maj_bit = (acc_sel >= 7'd37) ? 1'b1 : 1'b0;

  // SRAM write request
  sram_req_t sram_req_write;
  always_comb begin
    sram_req_write      = '0;
    sram_req_write.addr = out_byte_addr;
    sram_req_write.bm   = 8'h01 << out_bit_pos;
    sram_req_write.wen  = 1'b1;
    sram_req_write.din  = {7'b0, maj_bit} << out_bit_pos;
  end

  // SRAM mux
  always_comb begin
    if (state == WRITE_BIT)
      sram_req = sram_req_write;
    else
      sram_req = sram_req_load;
  end

  assign loader_read_en = (state == LOAD_WIN);
  assign done_o         = (state == DONE);

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    integer i, j;
    if (!rst_ni) begin
      state   <= IDLE;
      row_out <= 2'd0;
      ci      <= 3'd0;
      co      <= 4'd0;
      write_j <= 2'd0;
      for (i = 0; i < 16; i++)
        for (j = 0; j < 4; j++)
          acc[i][j] <= 7'd0;
    end else begin
      case (state)

        IDLE: begin
          if (start_i) begin
            row_out <= 2'd0;
            ci      <= 3'd0;
            co      <= 4'd0;
            write_j <= 2'd0;
            for (i = 0; i < 16; i++)
              for (j = 0; j < 4; j++)
                acc[i][j] <= 7'd0;
            state   <= LOAD_WIN;
          end
        end

        // Pulse read_en for one cycle; loader starts on this edge
        LOAD_WIN: state <= WAIT_READY;

        // Wait for loader (8 cycles: 7 pipeline + 1 register lag)
        WAIT_READY: begin
          if (loader_ready) begin
            co    <= 4'd0;
            state <= ACCUM_CO;
          end
        end

        // Cycle through all 16 output channels, accumulating popcounts
        // buffer_reg is valid (latched one cycle after loader_ready)
        ACCUM_CO: begin
          acc[co][0] <= acc[co][0] + {2'b00, conv_out0};
          acc[co][1] <= acc[co][1] + {2'b00, conv_out1};
          acc[co][2] <= acc[co][2] + {2'b00, conv_out2};
          acc[co][3] <= acc[co][3] + {2'b00, conv_out3};
          if (co == 4'd15) begin
            co    <= 4'd0;
            state <= ADVANCE_CI;
          end else begin
            co <= co + 4'd1;
          end
        end

        // Advance to next input channel or switch to write phase
        ADVANCE_CI: begin
          if (ci == 3'd7) begin
            ci      <= 3'd0;
            co      <= 4'd0;
            write_j <= 2'd0;
            state   <= WRITE_BIT;
          end else begin
            ci    <= ci + 3'd1;
            state <= LOAD_WIN;
          end
        end

        // Write one bit per cycle: all 16 co × 4 positions = 64 writes
        WRITE_BIT: begin
          if (write_j == 2'd3) begin
            write_j <= 2'd0;
            if (co == 4'd15) begin
              // Row complete — advance to next row or finish
              co <= 4'd0;
              ci <= 3'd0;
              // Clear accumulators for next row
              for (i = 0; i < 16; i++)
                for (j = 0; j < 4; j++)
                  acc[i][j] <= 7'd0;
              if (row_out == 2'd3)
                state <= DONE;
              else begin
                row_out <= row_out + 2'd1;
                state   <= LOAD_WIN;
              end
            end else begin
              co <= co + 4'd1;
            end
          end else begin
            write_j <= write_j + 2'd1;
          end
        end

        DONE: ;

        default: state <= IDLE;
      endcase
    end
  end

endmodule
