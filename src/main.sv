
// Full inference pipeline — top-level integration module.
//
// Pipeline (auto-sequenced after reset):
//   LOAD    mnist_loader       → SRAM[0..24]     14×14 input image
//   CONV1   conv_layer1        → SRAM[25..168]   8ch×12×12
//   POOL1   maxpool_2x2(8,12)  → SRAM[169..204]  8ch×6×6
//   CONV2   conv_layer2        → SRAM[205..236]  16ch×4×4
//   POOL2   maxpool_2x2(16,4)  → SRAM[237..244]  16ch×2×2
//   CONV3   conv_layer3        → SRAM[245..252]  64-bit embedding
//   TREE    classification_tree (combinational)  → number_o[3:0]
//
// The SRAM is single-port; each stage gets exclusive access in sequence.

module main (
  input  logic        clk_i,
  input  logic        rst_ni,

  // MNIST pixel input (from external source)
  input  logic        data_in_clk,
  input  logic [7:0]  data_in,

  // Inference result
  output logic [3:0]  number_o,
  output logic        inference_done_o,

  // SRAM bus (macro instantiated in top-level project.v)
  output logic [7:0]  sram_addr_o,
  output logic [7:0]  sram_bm_o,
  output logic        sram_wen_o,
  output logic        sram_ren_o,
  output logic [7:0]  sram_din_o,
  input  logic [7:0]  sram_dout_i
);

  // -----------------------------------------------------------------------
  // Shared SRAM bus
  // -----------------------------------------------------------------------
  sram_req_t sram_req;
  sram_rsp_t sram_rsp;

  assign sram_addr_o   = sram_req.addr;
  assign sram_bm_o     = sram_req.bm;
  assign sram_wen_o    = sram_req.wen;
  assign sram_ren_o    = sram_req.ren;
  assign sram_din_o    = sram_req.din;
  assign sram_rsp.dout = sram_dout_i;

  // -----------------------------------------------------------------------
  // Per-module SRAM req buses
  // -----------------------------------------------------------------------
  sram_req_t sram_req_mnist;
  sram_req_t sram_req_conv1;
  sram_req_t sram_req_pool1;
  sram_req_t sram_req_conv2;
  sram_req_t sram_req_pool2;
  sram_req_t sram_req_conv3;

  // -----------------------------------------------------------------------
  // Pipeline start / done signals
  // -----------------------------------------------------------------------
  logic mnist_done;
  logic conv1_start, conv1_done;
  logic pool1_start, pool1_done;
  logic conv2_start, conv2_done;
  logic pool2_start, pool2_done;
  logic conv3_start, conv3_done;

  // -----------------------------------------------------------------------
  // Module instances
  // -----------------------------------------------------------------------

  mnist_loader u_mnist_loader (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .sram_req    (sram_req_mnist),
    .sram_rsp    (sram_rsp),
    .data_in_clk (data_in_clk),
    .data_in     (data_in),
    .done_o      (mnist_done)
  );

  conv_layer1 u_conv1 (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .start_i (conv1_start),
    .done_o  (conv1_done),
    .sram_req(sram_req_conv1),
    .sram_rsp(sram_rsp)
  );

  maxpool_2x2 #(
    .NUM_CHANNELS (8),
    .IN_SIZE      (12),
    .INPUT_BASE   (25),
    .OUTPUT_BASE  (169)
  ) u_pool1 (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .start_i (pool1_start),
    .done_o  (pool1_done),
    .sram_req(sram_req_pool1),
    .sram_rsp(sram_rsp)
  );

  conv_layer2 u_conv2 (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .start_i (conv2_start),
    .done_o  (conv2_done),
    .sram_req(sram_req_conv2),
    .sram_rsp(sram_rsp)
  );

  maxpool_2x2 #(
    .NUM_CHANNELS (16),
    .IN_SIZE      (4),
    .INPUT_BASE   (205),
    .OUTPUT_BASE  (237)
  ) u_pool2 (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .start_i (pool2_start),
    .done_o  (pool2_done),
    .sram_req(sram_req_pool2),
    .sram_rsp(sram_rsp)
  );

  logic [63:0] embedding;

  conv_layer3 u_conv3 (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .start_i     (conv3_start),
    .done_o      (conv3_done),
    .embedding_o (embedding),
    .sram_req    (sram_req_conv3),
    .sram_rsp    (sram_rsp)
  );

  classification_tree u_tree (
    .embedding_i (embedding),
    .number_o    (number_o)
  );

  // -----------------------------------------------------------------------
  // Pipeline sequencer FSM
  // -----------------------------------------------------------------------
  typedef enum logic [2:0] {
    SEQ_LOAD,
    SEQ_CONV1,
    SEQ_POOL1,
    SEQ_CONV2,
    SEQ_POOL2,
    SEQ_CONV3,
    SEQ_DONE
  } seq_state_t;
  seq_state_t seq_state;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      seq_state        <= SEQ_LOAD;
      inference_done_o <= 1'b0;
      conv1_start      <= 1'b0;
      pool1_start      <= 1'b0;
      conv2_start      <= 1'b0;
      pool2_start      <= 1'b0;
      conv3_start      <= 1'b0;
    end else begin
      // Default: clear all start pulses
      conv1_start <= 1'b0;
      pool1_start <= 1'b0;
      conv2_start <= 1'b0;
      pool2_start <= 1'b0;
      conv3_start <= 1'b0;

      case (seq_state)
        SEQ_LOAD: begin
          inference_done_o <= 1'b0;
          if (mnist_done) begin
            conv1_start <= 1'b1;
            seq_state   <= SEQ_CONV1;
          end
        end

        SEQ_CONV1: begin
          if (conv1_done) begin
            pool1_start <= 1'b1;
            seq_state   <= SEQ_POOL1;
          end
        end

        SEQ_POOL1: begin
          if (pool1_done) begin
            conv2_start <= 1'b1;
            seq_state   <= SEQ_CONV2;
          end
        end

        SEQ_CONV2: begin
          if (conv2_done) begin
            pool2_start <= 1'b1;
            seq_state   <= SEQ_POOL2;
          end
        end

        SEQ_POOL2: begin
          if (pool2_done) begin
            conv3_start <= 1'b1;
            seq_state   <= SEQ_CONV3;
          end
        end

        SEQ_CONV3: begin
          if (conv3_done) begin
            inference_done_o <= 1'b1;
            seq_state        <= SEQ_DONE;
          end
        end

        SEQ_DONE: begin
          inference_done_o <= 1'b1;  // hold until reset
        end

        default: seq_state <= SEQ_LOAD;
      endcase
    end
  end

  // -----------------------------------------------------------------------
  // SRAM request mux — only the active stage drives the bus
  // -----------------------------------------------------------------------
  always_comb begin
    case (seq_state)
      SEQ_LOAD:  sram_req = sram_req_mnist;
      SEQ_CONV1: sram_req = sram_req_conv1;
      SEQ_POOL1: sram_req = sram_req_pool1;
      SEQ_CONV2: sram_req = sram_req_conv2;
      SEQ_POOL2: sram_req = sram_req_pool2;
      SEQ_CONV3: sram_req = sram_req_conv3;
      default:   sram_req = '0;
    endcase
  end

endmodule
