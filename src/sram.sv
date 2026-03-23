
typedef struct packed {
  logic [7:0] addr;
  logic [7:0] bm;
  logic       wen;
  logic       ren;
  logic [7:0] din;
} sram_req_t;

typedef struct packed {
  logic [7:0] dout;
} sram_rsp_t;


module sram_256x8_bm (
  input logic clk_i,
  input logic rst_ni,
  input sram_req_t sram_req,
  output sram_rsp_t sram_rsp
);
  
  RM_IHPSG13_1P_256x8_c3_bm_bist ihp_sram (
    .A_CLK(clk_i),
    .A_MEN(rst_ni),
    .A_WEN(sram_req.wen),
    .A_REN(sram_req.ren),
    .A_ADDR(sram_req.addr),
    .A_DIN(sram_req.din),
    .A_DLY(1'b1),
    .A_DOUT(sram_rsp.dout),
    .A_BM(sram_req.bm),
    // --- BIST disabled ---
    .A_BIST_EN  (1'b0),
    .A_BIST_CLK (1'b0),
    .A_BIST_MEN (1'b0),
    .A_BIST_REN (1'b0),
    .A_BIST_WEN (1'b0),
    .A_BIST_ADDR(8'h00),
    .A_BIST_DIN (8'h00),
    .A_BIST_BM  (8'h00)
  );

endmodule