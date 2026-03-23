
// 2×2 max-pool for binary feature maps.
//
// For 1-bit pixels, max({a,b,c,d}) = a | b | c | d  (OR gate).
//
// Supports any square input whose side length is even.
// The four pixels in each 2×2 window are packed across two SRAM bytes:
//   top pair  (row 2r,   col 2c and 2c+1) → always same byte (2c is even)
//   bottom pair (row 2r+1, col 2c and 2c+1) → always same byte (same reason)
// → only 2 SRAM reads per output pixel.
//
// Parameters:
//   NUM_CHANNELS  number of channels  (e.g. 8 for layer-1, 16 for layer-2)
//   IN_SIZE       spatial side length of input  (must be even; 12 or 4)
//   INPUT_BASE    SRAM byte address of first input byte
//   OUTPUT_BASE   SRAM byte address of first output byte
//
// Input  layout: channel-first, MSB-first row-major
//   linear_in  = ch * IN_SIZE²  + row_in * IN_SIZE  + col_in
//   byte_addr  = INPUT_BASE  + linear_in  / 8
//   bit_in_byte = 7 − (linear_in  % 8)
//
// Output layout: same convention, OUT_SIZE = IN_SIZE/2
//   linear_out = ch * OUT_SIZE² + row_out * OUT_SIZE + col_out
//   byte_addr  = OUTPUT_BASE + linear_out / 8
//   bit_in_byte = 7 − (linear_out % 8)
//
// FSM cycles per output pixel:
//   READ_TOP → WAIT_TOP → READ_BOT → WAIT_BOT → WRITE_BIT → ADVANCE  (6 cycles)
// Total L1 (8ch×36 px): 1728 cycles.
// Total L2 (16ch×4 px): 384 cycles.

module maxpool_2x2 #(
  parameter int NUM_CHANNELS = 8,
  parameter int IN_SIZE      = 12,   // must be even
  parameter int INPUT_BASE   = 25,
  parameter int OUTPUT_BASE  = 169
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic start_i,
  output logic done_o,

  output sram_req_t sram_req,
  input  sram_rsp_t sram_rsp
);

  // -----------------------------------------------------------------------
  // Derived constants
  // -----------------------------------------------------------------------
  localparam int OUT_SIZE   = IN_SIZE / 2;
  localparam int IN_CH_SZ   = IN_SIZE  * IN_SIZE;   // pixels per input channel
  localparam int OUT_CH_SZ  = OUT_SIZE * OUT_SIZE;   // pixels per output channel

  // -----------------------------------------------------------------------
  // FSM
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,
    READ_TOP,
    WAIT_TOP,
    READ_BOT,
    WAIT_BOT,
    WRITE_BIT,
    ADVANCE,
    DONE
  } state_t;
  state_t state;

  // -----------------------------------------------------------------------
  // Iteration counters
  // -----------------------------------------------------------------------
  logic [3:0] co;     // output channel  0..NUM_CHANNELS-1
  logic [3:0] r_out;  // output row      0..OUT_SIZE-1
  logic [3:0] c_out;  // output col      0..OUT_SIZE-1

  // -----------------------------------------------------------------------
  // Latched SRAM bytes
  // -----------------------------------------------------------------------
  logic [7:0] top_byte_reg;
  logic [7:0] bot_byte_reg;

  // -----------------------------------------------------------------------
  // Address & bit-position arithmetic
  // -----------------------------------------------------------------------

  // Input linear indices (12-bit covers both 8×144=1152 and 16×16=256)
  logic [11:0] linear_top;   // pixel (2*r_out,   2*c_out)
  logic [11:0] linear_bot;   // pixel (2*r_out+1, 2*c_out)
  logic [11:0] linear_out;   // output pixel

  assign linear_top = 12'(co) * 12'(IN_CH_SZ)
                    + 12'(r_out) * 12'(IN_SIZE * 2)   // 2*r_out * IN_SIZE
                    + 12'(c_out) * 12'(2);             // 2*c_out

  assign linear_bot = linear_top + 12'(IN_SIZE);       // same col, next row

  assign linear_out = 12'(co) * 12'(OUT_CH_SZ)
                    + 12'(r_out) * 12'(OUT_SIZE)
                    + 12'(c_out);

  // SRAM byte addresses
  logic [7:0] top_byte_addr;
  logic [7:0] bot_byte_addr;
  logic [7:0] out_byte_addr;

  assign top_byte_addr = 8'(INPUT_BASE)  + {1'b0, linear_top[11:3]};
  assign bot_byte_addr = 8'(INPUT_BASE)  + {1'b0, linear_bot[11:3]};
  assign out_byte_addr = 8'(OUTPUT_BASE) + {1'b0, linear_out[11:3]};

  // Bit positions within byte (MSB-first: bit 7 = first pixel)
  logic [2:0] top_bit0;  // pixel (2r, 2c)
  logic [2:0] top_bit1;  // pixel (2r, 2c+1)  = top_bit0 − 1
  logic [2:0] bot_bit0;  // pixel (2r+1, 2c)
  logic [2:0] bot_bit1;  // pixel (2r+1, 2c+1) = bot_bit0 − 1
  logic [2:0] out_bit;

  assign top_bit0 = 3'd7 - linear_top[2:0];
  assign top_bit1 = 3'd7 - (linear_top[2:0] + 3'd1);  // always top_bit0 − 1
  assign bot_bit0 = 3'd7 - linear_bot[2:0];
  assign bot_bit1 = 3'd7 - (linear_bot[2:0] + 3'd1);
  assign out_bit  = 3'd7 - linear_out[2:0];

  // -----------------------------------------------------------------------
  // OR of the four 2×2 pixels (max-pool for 1-bit activations)
  // -----------------------------------------------------------------------
  logic p00, p01, p10, p11, pool_result;

  assign p00 = top_byte_reg[top_bit0];
  assign p01 = top_byte_reg[top_bit1];
  assign p10 = bot_byte_reg[bot_bit0];
  assign p11 = bot_byte_reg[bot_bit1];
  assign pool_result = p00 | p01 | p10 | p11;

  // -----------------------------------------------------------------------
  // SRAM request mux
  // -----------------------------------------------------------------------
  always_comb begin
    sram_req      = '0;
    case (state)
      READ_TOP: begin
        sram_req.addr = top_byte_addr;
        sram_req.ren  = 1'b1;
      end
      READ_BOT: begin
        sram_req.addr = bot_byte_addr;
        sram_req.ren  = 1'b1;
      end
      WRITE_BIT: begin
        sram_req.addr = out_byte_addr;
        sram_req.bm   = 8'h01 << out_bit;
        sram_req.wen  = 1'b1;
        sram_req.din  = {7'b0, pool_result} << out_bit;
      end
      default: ;
    endcase
  end

  assign done_o = (state == DONE);

  // -----------------------------------------------------------------------
  // FSM + counters
  // -----------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state        <= IDLE;
      co           <= '0;
      r_out        <= '0;
      c_out        <= '0;
      top_byte_reg <= '0;
      bot_byte_reg <= '0;
    end else begin
      case (state)

        IDLE: begin
          if (start_i) begin
            co    <= '0;
            r_out <= '0;
            c_out <= '0;
            state <= READ_TOP;
          end
        end

        // Issue read for top byte; response arrives next cycle
        READ_TOP: state <= WAIT_TOP;

        // Latch top byte, then request bottom byte
        WAIT_TOP: begin
          top_byte_reg <= sram_rsp.dout;
          state        <= READ_BOT;
        end

        // Issue read for bottom byte
        READ_BOT: state <= WAIT_BOT;

        // Latch bottom byte; pool_result is combinational from both regs
        WAIT_BOT: begin
          bot_byte_reg <= sram_rsp.dout;
          state        <= WRITE_BIT;
        end

        // Write the OR'd bit into the output SRAM byte via byte-mask
        WRITE_BIT: state <= ADVANCE;

        // Advance: c_out → r_out → co
        ADVANCE: begin
          if (4'(c_out) == 4'(OUT_SIZE - 1)) begin
            c_out <= '0;
            if (4'(r_out) == 4'(OUT_SIZE - 1)) begin
              r_out <= '0;
              if (4'(co) == 4'(NUM_CHANNELS - 1))
                state <= DONE;
              else begin
                co    <= co + 4'd1;
                state <= READ_TOP;
              end
            end else begin
              r_out <= r_out + 4'd1;
              state <= READ_TOP;
            end
          end else begin
            c_out <= c_out + 4'd1;
            state <= READ_TOP;
          end
        end

        DONE: ;  // hold until reset

        default: state <= IDLE;
      endcase
    end
  end

endmodule
