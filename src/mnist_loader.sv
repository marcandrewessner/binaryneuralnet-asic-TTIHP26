
// This block loads the mnist data from the external world
// Pixels arrive as binary values packed in 2x2 blocks:
//   data_in[3:0] = 4 pixels of one 2x2 block  (OR-pooled to pixel_1)
//   data_in[7:4] = 4 pixels of next 2x2 block  (OR-pooled to pixel_2)
// Block ordering: row-major over the 14x14 grid, two blocks per packet.
// Total: 14x14/2 = 98 packets → 196 bits → packed 2 bits/packet into 25 SRAM bytes.
//
// Layout inside the original 28x28 grid:
// 0 1 4 5 x x x x x x x x x x x . . .
// 2 3 6 7 x x x x x x x x x x x . . .
// x x x x x x x x x x x x x x x . . .
// . . . . . . . . . . . . . . . . . .

module mnist_loader (
  input logic clk_i,
  input logic rst_ni,
  output sram_req_t sram_req,
  input sram_rsp_t sram_rsp,

  input logic data_in_clk,
  input logic [7:0] data_in,

  output logic done_o
);

  typedef enum logic [1:0] {
    CLK_IN_LOW,
    CLK_IN_HIGH
  } state_t;

  state_t     state;
  logic [6:0] packet_counter; // 0..98 (stops at 98 = done)

  // OR-pool each nibble: any high bit in the block → 1
  logic pixel_1, pixel_2;
  assign pixel_1 = |data_in[3:0];
  assign pixel_2 = |data_in[7:4];

  // SRAM address and bitmask are purely combinational from packet_counter.
  // Four packets share one SRAM byte: bits [7:6], [5:4], [3:2], [1:0].
  logic [7:0] addr;
  logic [2:0] bitmask_shift;
  logic [7:0] bitmask;
  logic [7:0] data;

  assign addr          = 8'(packet_counter) >> 2;           // packet / 4
  assign bitmask_shift = 3'((packet_counter % 4) * 2);      // 0, 2, 4, 6
  assign bitmask       = 8'b11000000 >> bitmask_shift;
  assign data          = ({pixel_1, pixel_2, 6'b000000}) >> bitmask_shift;

  // Write fires combinationally on the rising edge of data_in_clk
  // (state==CLK_IN_LOW && data_in_clk is the unregistered 0→1 transition).
  // This ensures the SRAM samples the current packet_counter on the clk_i
  // edge that also advances the counter — no off-by-one.
  assign done_o        = (packet_counter == 7'd98);

  assign sram_req.addr = addr;
  assign sram_req.bm   = bitmask;
  assign sram_req.din  = data;
  assign sram_req.wen  = (state == CLK_IN_LOW) && data_in_clk && !done_o;
  assign sram_req.ren  = 1'b0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      packet_counter <= 7'd0;
      state          <= CLK_IN_LOW;
    end else begin
      case (state)
        CLK_IN_LOW: begin
          if (data_in_clk) begin
            state <= CLK_IN_HIGH;
            if (!done_o)
              packet_counter <= packet_counter + 7'd1;
          end
        end
        CLK_IN_HIGH: begin
          if (!data_in_clk)
            state <= CLK_IN_LOW;
        end
        default: state <= CLK_IN_LOW;
      endcase
    end
  end

endmodule
