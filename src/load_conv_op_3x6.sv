
// This module loads a 3x6 = 18-bit binary pixel window from SRAM into buffer_o.
// The window layout:
//   buffer_o[17:12] = row 0, pixels 0..5
//   buffer_o[11:6]  = row 1, pixels 0..5
//   buffer_o[5:0]   = row 2, pixels 0..5
//
//   x x x x x x
//   x x x x x x
//   x x x x x x
//   = = =         CONV1
//     = = =       CONV2
//       = = =     CONV3
//         = = =   CONV4
//
// Each pixel is stored as 1 bit in SRAM, MSB-first:
//   pixel index p → byte (data_pointer + bit_addr/8), bit (7 - bit_addr%8)
//   where bit_addr = data_bit_offset + row*stride + col
//
// Timing: assert read_en_i for 1 cycle to start. ready_o pulses high for 1 cycle
// when buffer_o is valid (7 clock cycles after the start cycle).

module load_conv_op_3x6 (
  input logic clk_i,
  input logic rst_ni,

  output sram_req_t sram_req,
  input  sram_rsp_t sram_rsp,

  input logic        read_en_i,
  input logic [7:0]  stride_i,           // define the width of the input image
  input logic [7:0]  data_pointer_i,     // define the data address of the image in SRAM
  input logic [7:0]  data_bit_offset_i,  // define the bit offset of the image in SRAM

  output logic        ready_o,
  output logic [17:0] buffer_o
);

  // ---------------------------------------------------------------------------
  // Per-row absolute bit addresses (combinational)
  //   start_bit_rN = data_bit_offset_i + N * stride_i
  // ---------------------------------------------------------------------------
  logic [9:0] start_bit_r0, start_bit_r1, start_bit_r2;
  assign start_bit_r0 = {2'b00, data_bit_offset_i};
  assign start_bit_r1 = {2'b00, data_bit_offset_i} + {2'b00, stride_i};
  assign start_bit_r2 = {2'b00, data_bit_offset_i} + {1'b0, stride_i, 1'b0}; // 2*stride

  // Per-row SRAM byte addresses (A = first byte, B = second byte of each row)
  logic [7:0] addr_a0, addr_b0, addr_a1, addr_b1, addr_a2, addr_b2;
  assign addr_a0 = data_pointer_i + {1'b0, start_bit_r0[9:3]};
  assign addr_b0 = addr_a0 + 8'd1;
  assign addr_a1 = data_pointer_i + {1'b0, start_bit_r1[9:3]};
  assign addr_b1 = addr_a1 + 8'd1;
  assign addr_a2 = data_pointer_i + {1'b0, start_bit_r2[9:3]};
  assign addr_b2 = addr_a2 + 8'd1;

  // Per-row bit offset within the first byte (0 = MSB of byte)
  logic [2:0] bit_off_r0, bit_off_r1, bit_off_r2;
  assign bit_off_r0 = start_bit_r0[2:0];
  assign bit_off_r1 = start_bit_r1[2:0];
  assign bit_off_r2 = start_bit_r2[2:0];

  // ---------------------------------------------------------------------------
  // 6-pixel extraction from two consecutive SRAM bytes.
  //
  // Pixels are stored MSB-first.  Given {byte_a, byte_b} (16-bit), the 6-pixel
  // run starting at MSB offset bit_off sits at bits [15-bit_off : 10-bit_off].
  // Extract by shifting right by (10 - bit_off) and casting to [5:0].
  // bit_off in {0..7}  →  shift in {3..10}  (always non-negative).
  // ---------------------------------------------------------------------------
  function automatic logic [5:0] extract6(
    input logic [7:0] byte_a,
    input logic [7:0] byte_b,
    input logic [2:0] bit_off
  );
    logic [15:0] combined;
    logic [15:0] shifted;
    combined = {byte_a, byte_b};
    shifted = combined >> (4'd10 - {1'b0, bit_off});
    extract6 = shifted[5:0];
  endfunction

  // ---------------------------------------------------------------------------
  // State machine
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    WAIT,
    ROW_0_LOAD_A, ROW_0_LOAD_B,
    ROW_1_LOAD_A, ROW_1_LOAD_B,
    ROW_2_LOAD_A, ROW_2_LOAD_B,
    DONE
  } state_t;

  state_t     state;
  logic [7:0] byte_a_r; // registered first SRAM byte of the current row

  // ---------------------------------------------------------------------------
  // Combinational SRAM read request.
  // The request is presented while in each _LOAD_ state so the SRAM samples it
  // on the same posedge that transitions the FSM. dout is valid one cycle later
  // (A_DLY = 1 → output registered in the SRAM).
  // ---------------------------------------------------------------------------
  always_comb begin
    sram_req      = '0;
    sram_req.bm   = 8'hFF;
    case (state)
      ROW_0_LOAD_A: begin sram_req.ren = 1'b1; sram_req.addr = addr_a0; end
      ROW_0_LOAD_B: begin sram_req.ren = 1'b1; sram_req.addr = addr_b0; end
      ROW_1_LOAD_A: begin sram_req.ren = 1'b1; sram_req.addr = addr_a1; end
      ROW_1_LOAD_B: begin sram_req.ren = 1'b1; sram_req.addr = addr_b1; end
      ROW_2_LOAD_A: begin sram_req.ren = 1'b1; sram_req.addr = addr_a2; end
      ROW_2_LOAD_B: begin sram_req.ren = 1'b1; sram_req.addr = addr_b2; end
      default: ;
    endcase
  end

  // ---------------------------------------------------------------------------
  // Sequential FSM — captures SRAM responses and fills buffer_o row by row.
  //
  // Read pipeline per row (two SRAM reads needed because 6 pixels may straddle
  // a byte boundary):
  //   ROW_x_LOAD_A  →  ren issued for addr_aX this cycle; dout valid next cycle
  //   ROW_x_LOAD_B  →  dout = byte_aX; capture; ren issued for addr_bX
  //   next A state  →  dout = byte_bX; assemble 6 pixels from {byte_a_r, dout}
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state    <= WAIT;
      byte_a_r <= 8'h00;
      buffer_o <= 18'h0;
      ready_o  <= 1'b0;
    end else begin
      case (state)

        WAIT: begin
          ready_o <= 1'b0; // clear the done pulse from the previous load
          if (read_en_i)
            state <= ROW_0_LOAD_A;
        end

        // --- Row 0 ---
        ROW_0_LOAD_A: state <= ROW_0_LOAD_B; // ren→addr_a0; wait one cycle

        ROW_0_LOAD_B: begin                  // dout = byte_a0
          byte_a_r <= sram_rsp.dout;
          state    <= ROW_1_LOAD_A;
        end

        // --- Row 1 (completes row 0) ---
        ROW_1_LOAD_A: begin                  // dout = byte_b0 → row 0 done
          buffer_o[17:12] <= extract6(byte_a_r, sram_rsp.dout, bit_off_r0);
          state            <= ROW_1_LOAD_B;
        end

        ROW_1_LOAD_B: begin                  // dout = byte_a1
          byte_a_r <= sram_rsp.dout;
          state    <= ROW_2_LOAD_A;
        end

        // --- Row 2 (completes row 1) ---
        ROW_2_LOAD_A: begin                  // dout = byte_b1 → row 1 done
          buffer_o[11:6] <= extract6(byte_a_r, sram_rsp.dout, bit_off_r1);
          state           <= ROW_2_LOAD_B;
        end

        ROW_2_LOAD_B: begin                  // dout = byte_a2
          byte_a_r <= sram_rsp.dout;
          state    <= DONE;
        end

        // --- Done (completes row 2) ---
        DONE: begin                           // dout = byte_b2 → row 2 done
          buffer_o[5:0] <= extract6(byte_a_r, sram_rsp.dout, bit_off_r2);
          ready_o        <= 1'b1;
          state          <= WAIT;
        end

        default: state <= WAIT;
      endcase
    end
  end

endmodule
