
// BNN convolution layer 3: 2×2 input (16 ch) → 1×1 output (64 ch)
//
// Input:  SRAM[237..244]  — 16 channels × 2×2 binary = 64 bits = 8 bytes
//                           Linear index = ci*4 + row*2 + col
//                           byte 237 bit7=pixel(0,0,0) .. byte 244 bit0=pixel(15,1,1)
// Output: SRAM[245..252]  — 64 features = 8 bytes (bit co at byte 245+co/8, pos 7-co%8)
//
// embedding_o[63:0] is also exposed directly for the classification tree.
//
// Algorithm:
//   1. Load all 8 input bytes into input_buf[63:0]  (8 READ cycles)
//   2. Apply combinational conv_weights_2x2_l3 → result_buf[63:0]
//   3. Write 8 output bytes to SRAM                 (8 WRITE cycles)
//
// Total: ~20 cycles.

module conv_layer3 (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic start_i,
  output logic done_o,

  output logic [63:0] embedding_o,

  output sram_req_t sram_req,
  input  sram_rsp_t sram_rsp
);

  localparam logic [7:0] INPUT_BASE  = 8'd237;
  localparam logic [7:0] OUTPUT_BASE = 8'd245;

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,
    READ_BYTE,
    WAIT_BYTE,
    WRITE_BYTE,
    DONE
  } state_t;
  state_t state;

  logic [2:0] byte_idx;

  // -----------------------------------------------------------------------
  // Buffers
  // -----------------------------------------------------------------------
  logic [63:0] input_buf;
  logic [63:0] result_buf;

  // -----------------------------------------------------------------------
  // Combinational 2×2 BNN conv — all 64 outputs at once
  // -----------------------------------------------------------------------
  conv_weights_2x2_l3 u_weights (
    .data_in  (input_buf),
    .data_out (result_buf)
  );

  assign embedding_o = result_buf;

  // -----------------------------------------------------------------------
  // Byte encode helpers — MSB-first layout in SRAM:
  //   channel co stored at SRAM[245+co/8] bit (7-co%8)
  //   → channel co*8+0 goes to bit 7 (MSB) of byte co
  //   → write_byte[7-j] = result_buf[byte_idx*8 + j]
  // -----------------------------------------------------------------------
  logic [7:0] write_byte;
  always_comb begin
    case (byte_idx)
      3'd0: write_byte = {result_buf[0],  result_buf[1],  result_buf[2],  result_buf[3],
                          result_buf[4],  result_buf[5],  result_buf[6],  result_buf[7]};
      3'd1: write_byte = {result_buf[8],  result_buf[9],  result_buf[10], result_buf[11],
                          result_buf[12], result_buf[13], result_buf[14], result_buf[15]};
      3'd2: write_byte = {result_buf[16], result_buf[17], result_buf[18], result_buf[19],
                          result_buf[20], result_buf[21], result_buf[22], result_buf[23]};
      3'd3: write_byte = {result_buf[24], result_buf[25], result_buf[26], result_buf[27],
                          result_buf[28], result_buf[29], result_buf[30], result_buf[31]};
      3'd4: write_byte = {result_buf[32], result_buf[33], result_buf[34], result_buf[35],
                          result_buf[36], result_buf[37], result_buf[38], result_buf[39]};
      3'd5: write_byte = {result_buf[40], result_buf[41], result_buf[42], result_buf[43],
                          result_buf[44], result_buf[45], result_buf[46], result_buf[47]};
      3'd6: write_byte = {result_buf[48], result_buf[49], result_buf[50], result_buf[51],
                          result_buf[52], result_buf[53], result_buf[54], result_buf[55]};
      3'd7: write_byte = {result_buf[56], result_buf[57], result_buf[58], result_buf[59],
                          result_buf[60], result_buf[61], result_buf[62], result_buf[63]};
      default: write_byte = 8'd0;
    endcase
  end

  // -----------------------------------------------------------------------
  // SRAM request
  // -----------------------------------------------------------------------
  always_comb begin
    sram_req = '0;
    case (state)
      READ_BYTE: begin
        sram_req.addr = INPUT_BASE + {5'd0, byte_idx};
        sram_req.ren  = 1'b1;
      end
      WRITE_BYTE: begin
        sram_req.addr = OUTPUT_BASE + {5'd0, byte_idx};
        sram_req.wen  = 1'b1;
        sram_req.bm   = 8'hFF;
        sram_req.din  = write_byte;
      end
      default: ;
    endcase
  end

  assign done_o = (state == DONE);

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state     <= IDLE;
      byte_idx  <= 3'd0;
      input_buf <= 64'd0;
    end else begin
      case (state)

        IDLE: begin
          if (start_i) begin
            byte_idx  <= 3'd0;
            input_buf <= 64'd0;
            state     <= READ_BYTE;
          end
        end

        // Issue read; response arrives next cycle (A_DLY=1)
        READ_BYTE: state <= WAIT_BYTE;

        // Latch received byte
        WAIT_BYTE: begin
          case (byte_idx)
            3'd0: input_buf[63:56] <= sram_rsp.dout;
            3'd1: input_buf[55:48] <= sram_rsp.dout;
            3'd2: input_buf[47:40] <= sram_rsp.dout;
            3'd3: input_buf[39:32] <= sram_rsp.dout;
            3'd4: input_buf[31:24] <= sram_rsp.dout;
            3'd5: input_buf[23:16] <= sram_rsp.dout;
            3'd6: input_buf[15: 8] <= sram_rsp.dout;
            3'd7: input_buf[ 7: 0] <= sram_rsp.dout;
            default: ;
          endcase
          if (byte_idx == 3'd7) begin
            byte_idx <= 3'd0;
            state    <= WRITE_BYTE;
          end else begin
            byte_idx <= byte_idx + 3'd1;
            state    <= READ_BYTE;
          end
        end

        // Write result byte-by-byte (result_buf combinational from input_buf)
        WRITE_BYTE: begin
          if (byte_idx == 3'd7)
            state <= DONE;
          else
            byte_idx <= byte_idx + 3'd1;
        end

        DONE: ;

        default: state <= IDLE;
      endcase
    end
  end

endmodule
