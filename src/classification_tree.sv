
// ============================================
//   DONT TOUCH THIS IS GENERATED! // CODEGEN
// ============================================
//
// Classification tree for MNIST (10 classes, binarized embeddings)
//
// Input:  embedding_i[63:0]
//           bit i = 1  →  feature e_i = +1
//           bit i = 0  →  feature e_i = -1
//
// Output: number_o[3:0]  predicted class 0-9
//
// Structure:
//   10 boosting rounds × 10 classes = 100 trees
//   Each tree returns a 2-bit quantized leaf score (0-3)
//   Per-class score = sum of 10 tree outputs  (0-30, 5 bits)
//   Argmax over 10 scores → output class
module classification_tree (
  input  logic [63:0] embedding_i,
  output logic  [3:0] number_o
);

  // ── Per-tree combinational functions ────────────────────────────────────
  // tree 0: class 0, round 0
  function automatic [1:0] tree_0;
    input logic [63:0] emb;
  begin
  if (!emb[23]) begin  // e23==-1
    if (!emb[21]) begin  // e21==-1
      if (!emb[58]) begin  // e58==-1
        tree_0 = 2'd0;
      end else begin  // e58==+1
        tree_0 = 2'd3;
      end
    end else begin  // e21==+1
      if (!emb[10]) begin  // e10==-1
        tree_0 = 2'd3;
      end else begin  // e10==+1
        tree_0 = 2'd3;
      end
    end
  end else begin  // e23==+1
    if (!emb[27]) begin  // e27==-1
      if (!emb[33]) begin  // e33==-1
        tree_0 = 2'd0;
      end else begin  // e33==+1
        tree_0 = 2'd0;
      end
    end else begin  // e27==+1
      if (!emb[24]) begin  // e24==-1
        tree_0 = 2'd2;
      end else begin  // e24==+1
        tree_0 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 1: class 1, round 0
  function automatic [1:0] tree_1;
    input logic [63:0] emb;
  begin
  if (!emb[41]) begin  // e41==-1
    if (!emb[32]) begin  // e32==-1
      if (!emb[17]) begin  // e17==-1
        tree_1 = 2'd0;
      end else begin  // e17==+1
        tree_1 = 2'd3;
      end
    end else begin  // e32==+1
      if (!emb[38]) begin  // e38==-1
        tree_1 = 2'd0;
      end else begin  // e38==+1
        tree_1 = 2'd0;
      end
    end
  end else begin  // e41==+1
    if (!emb[62]) begin  // e62==-1
      if (!emb[33]) begin  // e33==-1
        tree_1 = 2'd3;
      end else begin  // e33==+1
        tree_1 = 2'd3;
      end
    end else begin  // e62==+1
      if (!emb[43]) begin  // e43==-1
        tree_1 = 2'd0;
      end else begin  // e43==+1
        tree_1 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 2: class 2, round 0
  function automatic [1:0] tree_2;
    input logic [63:0] emb;
  begin
  if (!emb[6]) begin  // e6==-1
    if (!emb[31]) begin  // e31==-1
      if (!emb[44]) begin  // e44==-1
        tree_2 = 2'd3;
      end else begin  // e44==+1
        tree_2 = 2'd3;
      end
    end else begin  // e31==+1
      if (!emb[44]) begin  // e44==-1
        tree_2 = 2'd0;
      end else begin  // e44==+1
        tree_2 = 2'd3;
      end
    end
  end else begin  // e6==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[14]) begin  // e14==-1
        tree_2 = 2'd0;
      end else begin  // e14==+1
        tree_2 = 2'd3;
      end
    end else begin  // e19==+1
      if (!emb[50]) begin  // e50==-1
        tree_2 = 2'd0;
      end else begin  // e50==+1
        tree_2 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 3: class 3, round 0
  function automatic [1:0] tree_3;
    input logic [63:0] emb;
  begin
  if (!emb[30]) begin  // e30==-1
    if (!emb[0]) begin  // e0==-1
      if (!emb[4]) begin  // e4==-1
        tree_3 = 2'd2;
      end else begin  // e4==+1
        tree_3 = 2'd3;
      end
    end else begin  // e0==+1
      if (!emb[27]) begin  // e27==-1
        tree_3 = 2'd0;
      end else begin  // e27==+1
        tree_3 = 2'd3;
      end
    end
  end else begin  // e30==+1
    if (!emb[27]) begin  // e27==-1
      if (!emb[59]) begin  // e59==-1
        tree_3 = 2'd0;
      end else begin  // e59==+1
        tree_3 = 2'd0;
      end
    end else begin  // e27==+1
      if (!emb[59]) begin  // e59==-1
        tree_3 = 2'd0;
      end else begin  // e59==+1
        tree_3 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 4: class 4, round 0
  function automatic [1:0] tree_4;
    input logic [63:0] emb;
  begin
  if (!emb[55]) begin  // e55==-1
    if (!emb[46]) begin  // e46==-1
      if (!emb[22]) begin  // e22==-1
        tree_4 = 2'd3;
      end else begin  // e22==+1
        tree_4 = 2'd3;
      end
    end else begin  // e46==+1
      if (!emb[28]) begin  // e28==-1
        tree_4 = 2'd0;
      end else begin  // e28==+1
        tree_4 = 2'd2;
      end
    end
  end else begin  // e55==+1
    if (!emb[39]) begin  // e39==-1
      if (!emb[35]) begin  // e35==-1
        tree_4 = 2'd0;
      end else begin  // e35==+1
        tree_4 = 2'd0;
      end
    end else begin  // e39==+1
      if (!emb[57]) begin  // e57==-1
        tree_4 = 2'd3;
      end else begin  // e57==+1
        tree_4 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 5: class 5, round 0
  function automatic [1:0] tree_5;
    input logic [63:0] emb;
  begin
  if (!emb[24]) begin  // e24==-1
    if (!emb[0]) begin  // e0==-1
      if (!emb[39]) begin  // e39==-1
        tree_5 = 2'd2;
      end else begin  // e39==+1
        tree_5 = 2'd0;
      end
    end else begin  // e0==+1
      if (!emb[62]) begin  // e62==-1
        tree_5 = 2'd1;
      end else begin  // e62==+1
        tree_5 = 2'd0;
      end
    end
  end else begin  // e24==+1
    if (!emb[38]) begin  // e38==-1
      if (!emb[28]) begin  // e28==-1
        tree_5 = 2'd0;
      end else begin  // e28==+1
        tree_5 = 2'd2;
      end
    end else begin  // e38==+1
      if (!emb[15]) begin  // e15==-1
        tree_5 = 2'd3;
      end else begin  // e15==+1
        tree_5 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 6: class 6, round 0
  function automatic [1:0] tree_6;
    input logic [63:0] emb;
  begin
  if (!emb[8]) begin  // e8==-1
    if (!emb[16]) begin  // e16==-1
      if (!emb[19]) begin  // e19==-1
        tree_6 = 2'd3;
      end else begin  // e19==+1
        tree_6 = 2'd1;
      end
    end else begin  // e16==+1
      if (!emb[19]) begin  // e19==-1
        tree_6 = 2'd2;
      end else begin  // e19==+1
        tree_6 = 2'd0;
      end
    end
  end else begin  // e8==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[55]) begin  // e55==-1
        tree_6 = 2'd3;
      end else begin  // e55==+1
        tree_6 = 2'd0;
      end
    end else begin  // e19==+1
      if (!emb[33]) begin  // e33==-1
        tree_6 = 2'd0;
      end else begin  // e33==+1
        tree_6 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 7: class 7, round 0
  function automatic [1:0] tree_7;
    input logic [63:0] emb;
  begin
  if (!emb[61]) begin  // e61==-1
    if (!emb[33]) begin  // e33==-1
      if (!emb[1]) begin  // e1==-1
        tree_7 = 2'd1;
      end else begin  // e1==+1
        tree_7 = 2'd3;
      end
    end else begin  // e33==+1
      if (!emb[31]) begin  // e31==-1
        tree_7 = 2'd0;
      end else begin  // e31==+1
        tree_7 = 2'd0;
      end
    end
  end else begin  // e61==+1
    if (!emb[57]) begin  // e57==-1
      if (!emb[31]) begin  // e31==-1
        tree_7 = 2'd0;
      end else begin  // e31==+1
        tree_7 = 2'd3;
      end
    end else begin  // e57==+1
      if (!emb[31]) begin  // e31==-1
        tree_7 = 2'd3;
      end else begin  // e31==+1
        tree_7 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 8: class 8, round 0
  function automatic [1:0] tree_8;
    input logic [63:0] emb;
  begin
  if (!emb[58]) begin  // e58==-1
    if (!emb[57]) begin  // e57==-1
      if (!emb[5]) begin  // e5==-1
        tree_8 = 2'd0;
      end else begin  // e5==+1
        tree_8 = 2'd0;
      end
    end else begin  // e57==+1
      if (!emb[49]) begin  // e49==-1
        tree_8 = 2'd2;
      end else begin  // e49==+1
        tree_8 = 2'd0;
      end
    end
  end else begin  // e58==+1
    if (!emb[49]) begin  // e49==-1
      if (!emb[44]) begin  // e44==-1
        tree_8 = 2'd3;
      end else begin  // e44==+1
        tree_8 = 2'd3;
      end
    end else begin  // e49==+1
      if (!emb[23]) begin  // e23==-1
        tree_8 = 2'd0;
      end else begin  // e23==+1
        tree_8 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 9: class 9, round 0
  function automatic [1:0] tree_9;
    input logic [63:0] emb;
  begin
  if (!emb[55]) begin  // e55==-1
    if (!emb[6]) begin  // e6==-1
      if (!emb[48]) begin  // e48==-1
        tree_9 = 2'd0;
      end else begin  // e48==+1
        tree_9 = 2'd3;
      end
    end else begin  // e6==+1
      if (!emb[38]) begin  // e38==-1
        tree_9 = 2'd3;
      end else begin  // e38==+1
        tree_9 = 2'd3;
      end
    end
  end else begin  // e55==+1
    if (!emb[50]) begin  // e50==-1
      if (!emb[31]) begin  // e31==-1
        tree_9 = 2'd1;
      end else begin  // e31==+1
        tree_9 = 2'd3;
      end
    end else begin  // e50==+1
      if (!emb[39]) begin  // e39==-1
        tree_9 = 2'd0;
      end else begin  // e39==+1
        tree_9 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 10: class 0, round 1
  function automatic [1:0] tree_10;
    input logic [63:0] emb;
  begin
  if (!emb[27]) begin  // e27==-1
    if (!emb[58]) begin  // e58==-1
      if (!emb[23]) begin  // e23==-1
        tree_10 = 2'd0;
      end else begin  // e23==+1
        tree_10 = 2'd0;
      end
    end else begin  // e58==+1
      if (!emb[13]) begin  // e13==-1
        tree_10 = 2'd2;
      end else begin  // e13==+1
        tree_10 = 2'd0;
      end
    end
  end else begin  // e27==+1
    if (!emb[45]) begin  // e45==-1
      if (!emb[1]) begin  // e1==-1
        tree_10 = 2'd2;
      end else begin  // e1==+1
        tree_10 = 2'd3;
      end
    end else begin  // e45==+1
      if (!emb[23]) begin  // e23==-1
        tree_10 = 2'd0;
      end else begin  // e23==+1
        tree_10 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 11: class 1, round 1
  function automatic [1:0] tree_11;
    input logic [63:0] emb;
  begin
  if (!emb[38]) begin  // e38==-1
    if (!emb[39]) begin  // e39==-1
      if (!emb[33]) begin  // e33==-1
        tree_11 = 2'd3;
      end else begin  // e33==+1
        tree_11 = 2'd1;
      end
    end else begin  // e39==+1
      if (!emb[20]) begin  // e20==-1
        tree_11 = 2'd1;
      end else begin  // e20==+1
        tree_11 = 2'd0;
      end
    end
  end else begin  // e38==+1
    if (!emb[41]) begin  // e41==-1
      tree_11 = 2'd0;
    end else begin  // e41==+1
      if (!emb[39]) begin  // e39==-1
        tree_11 = 2'd1;
      end else begin  // e39==+1
        tree_11 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 12: class 2, round 1
  function automatic [1:0] tree_12;
    input logic [63:0] emb;
  begin
  if (!emb[14]) begin  // e14==-1
    if (!emb[50]) begin  // e50==-1
      if (!emb[21]) begin  // e21==-1
        tree_12 = 2'd0;
      end else begin  // e21==+1
        tree_12 = 2'd2;
      end
    end else begin  // e50==+1
      if (!emb[41]) begin  // e41==-1
        tree_12 = 2'd1;
      end else begin  // e41==+1
        tree_12 = 2'd3;
      end
    end
  end else begin  // e14==+1
    if (!emb[0]) begin  // e0==-1
      if (!emb[38]) begin  // e38==-1
        tree_12 = 2'd3;
      end else begin  // e38==+1
        tree_12 = 2'd0;
      end
    end else begin  // e0==+1
      if (!emb[19]) begin  // e19==-1
        tree_12 = 2'd3;
      end else begin  // e19==+1
        tree_12 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 13: class 3, round 1
  function automatic [1:0] tree_13;
    input logic [63:0] emb;
  begin
  if (!emb[35]) begin  // e35==-1
    if (!emb[44]) begin  // e44==-1
      if (!emb[50]) begin  // e50==-1
        tree_13 = 2'd0;
      end else begin  // e50==+1
        tree_13 = 2'd1;
      end
    end else begin  // e44==+1
      if (!emb[37]) begin  // e37==-1
        tree_13 = 2'd1;
      end else begin  // e37==+1
        tree_13 = 2'd2;
      end
    end
  end else begin  // e35==+1
    if (!emb[15]) begin  // e15==-1
      if (!emb[39]) begin  // e39==-1
        tree_13 = 2'd3;
      end else begin  // e39==+1
        tree_13 = 2'd2;
      end
    end else begin  // e15==+1
      if (!emb[6]) begin  // e6==-1
        tree_13 = 2'd3;
      end else begin  // e6==+1
        tree_13 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 14: class 4, round 1
  function automatic [1:0] tree_14;
    input logic [63:0] emb;
  begin
  if (!emb[27]) begin  // e27==-1
    if (!emb[2]) begin  // e2==-1
      if (!emb[19]) begin  // e19==-1
        tree_14 = 2'd2;
      end else begin  // e19==+1
        tree_14 = 2'd3;
      end
    end else begin  // e2==+1
      if (!emb[50]) begin  // e50==-1
        tree_14 = 2'd2;
      end else begin  // e50==+1
        tree_14 = 2'd0;
      end
    end
  end else begin  // e27==+1
    if (!emb[50]) begin  // e50==-1
      if (!emb[16]) begin  // e16==-1
        tree_14 = 2'd3;
      end else begin  // e16==+1
        tree_14 = 2'd0;
      end
    end else begin  // e50==+1
      if (!emb[35]) begin  // e35==-1
        tree_14 = 2'd0;
      end else begin  // e35==+1
        tree_14 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 15: class 5, round 1
  function automatic [1:0] tree_15;
    input logic [63:0] emb;
  begin
  if (!emb[35]) begin  // e35==-1
    if (!emb[62]) begin  // e62==-1
      if (!emb[26]) begin  // e26==-1
        tree_15 = 2'd3;
      end else begin  // e26==+1
        tree_15 = 2'd1;
      end
    end else begin  // e62==+1
      if (!emb[8]) begin  // e8==-1
        tree_15 = 2'd1;
      end else begin  // e8==+1
        tree_15 = 2'd0;
      end
    end
  end else begin  // e35==+1
    if (!emb[17]) begin  // e17==-1
      if (!emb[28]) begin  // e28==-1
        tree_15 = 2'd2;
      end else begin  // e28==+1
        tree_15 = 2'd3;
      end
    end else begin  // e17==+1
      if (!emb[8]) begin  // e8==-1
        tree_15 = 2'd3;
      end else begin  // e8==+1
        tree_15 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 16: class 6, round 1
  function automatic [1:0] tree_16;
    input logic [63:0] emb;
  begin
  if (!emb[59]) begin  // e59==-1
    if (!emb[10]) begin  // e10==-1
      if (!emb[17]) begin  // e17==-1
        tree_16 = 2'd3;
      end else begin  // e17==+1
        tree_16 = 2'd1;
      end
    end else begin  // e10==+1
      if (!emb[40]) begin  // e40==-1
        tree_16 = 2'd1;
      end else begin  // e40==+1
        tree_16 = 2'd0;
      end
    end
  end else begin  // e59==+1
    if (!emb[30]) begin  // e30==-1
      if (!emb[16]) begin  // e16==-1
        tree_16 = 2'd0;
      end else begin  // e16==+1
        tree_16 = 2'd0;
      end
    end else begin  // e30==+1
      if (!emb[33]) begin  // e33==-1
        tree_16 = 2'd0;
      end else begin  // e33==+1
        tree_16 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 17: class 7, round 1
  function automatic [1:0] tree_17;
    input logic [63:0] emb;
  begin
  if (!emb[33]) begin  // e33==-1
    if (!emb[35]) begin  // e35==-1
      if (!emb[1]) begin  // e1==-1
        tree_17 = 2'd0;
      end else begin  // e1==+1
        tree_17 = 2'd1;
      end
    end else begin  // e35==+1
      if (!emb[39]) begin  // e39==-1
        tree_17 = 2'd2;
      end else begin  // e39==+1
        tree_17 = 2'd3;
      end
    end
  end else begin  // e33==+1
    if (!emb[18]) begin  // e18==-1
      if (!emb[63]) begin  // e63==-1
        tree_17 = 2'd1;
      end else begin  // e63==+1
        tree_17 = 2'd3;
      end
    end else begin  // e18==+1
      if (!emb[17]) begin  // e17==-1
        tree_17 = 2'd0;
      end else begin  // e17==+1
        tree_17 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 18: class 8, round 1
  function automatic [1:0] tree_18;
    input logic [63:0] emb;
  begin
  if (!emb[57]) begin  // e57==-1
    if (!emb[62]) begin  // e62==-1
      if (!emb[53]) begin  // e53==-1
        tree_18 = 2'd0;
      end else begin  // e53==+1
        tree_18 = 2'd2;
      end
    end else begin  // e62==+1
      if (!emb[2]) begin  // e2==-1
        tree_18 = 2'd0;
      end else begin  // e2==+1
        tree_18 = 2'd0;
      end
    end
  end else begin  // e57==+1
    if (!emb[35]) begin  // e35==-1
      if (!emb[21]) begin  // e21==-1
        tree_18 = 2'd3;
      end else begin  // e21==+1
        tree_18 = 2'd1;
      end
    end else begin  // e35==+1
      if (!emb[45]) begin  // e45==-1
        tree_18 = 2'd1;
      end else begin  // e45==+1
        tree_18 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 19: class 9, round 1
  function automatic [1:0] tree_19;
    input logic [63:0] emb;
  begin
  if (!emb[39]) begin  // e39==-1
    if (!emb[33]) begin  // e33==-1
      if (!emb[32]) begin  // e32==-1
        tree_19 = 2'd0;
      end else begin  // e32==+1
        tree_19 = 2'd3;
      end
    end else begin  // e33==+1
      if (!emb[48]) begin  // e48==-1
        tree_19 = 2'd0;
      end else begin  // e48==+1
        tree_19 = 2'd1;
      end
    end
  end else begin  // e39==+1
    if (!emb[56]) begin  // e56==-1
      if (!emb[5]) begin  // e5==-1
        tree_19 = 2'd3;
      end else begin  // e5==+1
        tree_19 = 2'd3;
      end
    end else begin  // e56==+1
      if (!emb[22]) begin  // e22==-1
        tree_19 = 2'd0;
      end else begin  // e22==+1
        tree_19 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 20: class 0, round 2
  function automatic [1:0] tree_20;
    input logic [63:0] emb;
  begin
  if (!emb[59]) begin  // e59==-1
    if (!emb[3]) begin  // e3==-1
      if (!emb[16]) begin  // e16==-1
        tree_20 = 2'd0;
      end else begin  // e16==+1
        tree_20 = 2'd1;
      end
    end else begin  // e3==+1
      if (!emb[27]) begin  // e27==-1
        tree_20 = 2'd1;
      end else begin  // e27==+1
        tree_20 = 2'd3;
      end
    end
  end else begin  // e59==+1
    if (!emb[58]) begin  // e58==-1
      if (!emb[10]) begin  // e10==-1
        tree_20 = 2'd0;
      end else begin  // e10==+1
        tree_20 = 2'd0;
      end
    end else begin  // e58==+1
      if (!emb[18]) begin  // e18==-1
        tree_20 = 2'd3;
      end else begin  // e18==+1
        tree_20 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 21: class 1, round 2
  function automatic [1:0] tree_21;
    input logic [63:0] emb;
  begin
  if (!emb[38]) begin  // e38==-1
    if (!emb[37]) begin  // e37==-1
      if (!emb[15]) begin  // e15==-1
        tree_21 = 2'd1;
      end else begin  // e15==+1
        tree_21 = 2'd3;
      end
    end else begin  // e37==+1
      if (!emb[26]) begin  // e26==-1
        tree_21 = 2'd0;
      end else begin  // e26==+1
        tree_21 = 2'd1;
      end
    end
  end else begin  // e38==+1
    if (!emb[49]) begin  // e49==-1
      if (!emb[41]) begin  // e41==-1
        tree_21 = 2'd0;
      end else begin  // e41==+1
        tree_21 = 2'd1;
      end
    end else begin  // e49==+1
      if (!emb[41]) begin  // e41==-1
        tree_21 = 2'd0;
      end else begin  // e41==+1
        tree_21 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 22: class 2, round 2
  function automatic [1:0] tree_22;
    input logic [63:0] emb;
  begin
  if (!emb[6]) begin  // e6==-1
    if (!emb[36]) begin  // e36==-1
      if (!emb[21]) begin  // e21==-1
        tree_22 = 2'd2;
      end else begin  // e21==+1
        tree_22 = 2'd3;
      end
    end else begin  // e36==+1
      if (!emb[38]) begin  // e38==-1
        tree_22 = 2'd3;
      end else begin  // e38==+1
        tree_22 = 2'd1;
      end
    end
  end else begin  // e6==+1
    if (!emb[44]) begin  // e44==-1
      if (!emb[19]) begin  // e19==-1
        tree_22 = 2'd1;
      end else begin  // e19==+1
        tree_22 = 2'd0;
      end
    end else begin  // e44==+1
      if (!emb[29]) begin  // e29==-1
        tree_22 = 2'd3;
      end else begin  // e29==+1
        tree_22 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 23: class 3, round 2
  function automatic [1:0] tree_23;
    input logic [63:0] emb;
  begin
  if (!emb[35]) begin  // e35==-1
    if (!emb[42]) begin  // e42==-1
      if (!emb[46]) begin  // e46==-1
        tree_23 = 2'd1;
      end else begin  // e46==+1
        tree_23 = 2'd3;
      end
    end else begin  // e42==+1
      if (!emb[30]) begin  // e30==-1
        tree_23 = 2'd1;
      end else begin  // e30==+1
        tree_23 = 2'd0;
      end
    end
  end else begin  // e35==+1
    if (!emb[44]) begin  // e44==-1
      if (!emb[50]) begin  // e50==-1
        tree_23 = 2'd1;
      end else begin  // e50==+1
        tree_23 = 2'd2;
      end
    end else begin  // e44==+1
      if (!emb[43]) begin  // e43==-1
        tree_23 = 2'd3;
      end else begin  // e43==+1
        tree_23 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 24: class 4, round 2
  function automatic [1:0] tree_24;
    input logic [63:0] emb;
  begin
  if (!emb[39]) begin  // e39==-1
    if (!emb[35]) begin  // e35==-1
      if (!emb[48]) begin  // e48==-1
        tree_24 = 2'd1;
      end else begin  // e48==+1
        tree_24 = 2'd3;
      end
    end else begin  // e35==+1
      if (!emb[50]) begin  // e50==-1
        tree_24 = 2'd0;
      end else begin  // e50==+1
        tree_24 = 2'd0;
      end
    end
  end else begin  // e39==+1
    if (!emb[15]) begin  // e15==-1
      if (!emb[8]) begin  // e8==-1
        tree_24 = 2'd2;
      end else begin  // e8==+1
        tree_24 = 2'd1;
      end
    end else begin  // e15==+1
      if (!emb[43]) begin  // e43==-1
        tree_24 = 2'd3;
      end else begin  // e43==+1
        tree_24 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 25: class 5, round 2
  function automatic [1:0] tree_25;
    input logic [63:0] emb;
  begin
  if (!emb[8]) begin  // e8==-1
    if (!emb[4]) begin  // e4==-1
      if (!emb[35]) begin  // e35==-1
        tree_25 = 2'd1;
      end else begin  // e35==+1
        tree_25 = 2'd2;
      end
    end else begin  // e4==+1
      if (!emb[60]) begin  // e60==-1
        tree_25 = 2'd3;
      end else begin  // e60==+1
        tree_25 = 2'd3;
      end
    end
  end else begin  // e8==+1
    if (!emb[60]) begin  // e60==-1
      if (!emb[2]) begin  // e2==-1
        tree_25 = 2'd2;
      end else begin  // e2==+1
        tree_25 = 2'd0;
      end
    end else begin  // e60==+1
      if (!emb[18]) begin  // e18==-1
        tree_25 = 2'd0;
      end else begin  // e18==+1
        tree_25 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 26: class 6, round 2
  function automatic [1:0] tree_26;
    input logic [63:0] emb;
  begin
  if (!emb[30]) begin  // e30==-1
    if (!emb[55]) begin  // e55==-1
      if (!emb[37]) begin  // e37==-1
        tree_26 = 2'd3;
      end else begin  // e37==+1
        tree_26 = 2'd0;
      end
    end else begin  // e55==+1
      if (!emb[36]) begin  // e36==-1
        tree_26 = 2'd0;
      end else begin  // e36==+1
        tree_26 = 2'd0;
      end
    end
  end else begin  // e30==+1
    if (!emb[21]) begin  // e21==-1
      if (!emb[19]) begin  // e19==-1
        tree_26 = 2'd2;
      end else begin  // e19==+1
        tree_26 = 2'd0;
      end
    end else begin  // e21==+1
      if (!emb[55]) begin  // e55==-1
        tree_26 = 2'd3;
      end else begin  // e55==+1
        tree_26 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 27: class 7, round 2
  function automatic [1:0] tree_27;
    input logic [63:0] emb;
  begin
  if (!emb[29]) begin  // e29==-1
    if (!emb[8]) begin  // e8==-1
      if (!emb[52]) begin  // e52==-1
        tree_27 = 2'd0;
      end else begin  // e52==+1
        tree_27 = 2'd2;
      end
    end else begin  // e8==+1
      if (!emb[39]) begin  // e39==-1
        tree_27 = 2'd2;
      end else begin  // e39==+1
        tree_27 = 2'd3;
      end
    end
  end else begin  // e29==+1
    if (!emb[18]) begin  // e18==-1
      if (!emb[54]) begin  // e54==-1
        tree_27 = 2'd0;
      end else begin  // e54==+1
        tree_27 = 2'd3;
      end
    end else begin  // e18==+1
      if (!emb[56]) begin  // e56==-1
        tree_27 = 2'd0;
      end else begin  // e56==+1
        tree_27 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 28: class 8, round 2
  function automatic [1:0] tree_28;
    input logic [63:0] emb;
  begin
  if (!emb[57]) begin  // e57==-1
    if (!emb[62]) begin  // e62==-1
      if (!emb[52]) begin  // e52==-1
        tree_28 = 2'd1;
      end else begin  // e52==+1
        tree_28 = 2'd2;
      end
    end else begin  // e62==+1
      if (!emb[24]) begin  // e24==-1
        tree_28 = 2'd0;
      end else begin  // e24==+1
        tree_28 = 2'd0;
      end
    end
  end else begin  // e57==+1
    if (!emb[37]) begin  // e37==-1
      if (!emb[9]) begin  // e9==-1
        tree_28 = 2'd2;
      end else begin  // e9==+1
        tree_28 = 2'd3;
      end
    end else begin  // e37==+1
      if (!emb[45]) begin  // e45==-1
        tree_28 = 2'd1;
      end else begin  // e45==+1
        tree_28 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 29: class 9, round 2
  function automatic [1:0] tree_29;
    input logic [63:0] emb;
  begin
  if (!emb[33]) begin  // e33==-1
    if (!emb[49]) begin  // e49==-1
      if (!emb[46]) begin  // e46==-1
        tree_29 = 2'd3;
      end else begin  // e46==+1
        tree_29 = 2'd2;
      end
    end else begin  // e49==+1
      if (!emb[61]) begin  // e61==-1
        tree_29 = 2'd3;
      end else begin  // e61==+1
        tree_29 = 2'd1;
      end
    end
  end else begin  // e33==+1
    if (!emb[48]) begin  // e48==-1
      if (!emb[17]) begin  // e17==-1
        tree_29 = 2'd0;
      end else begin  // e17==+1
        tree_29 = 2'd2;
      end
    end else begin  // e48==+1
      if (!emb[46]) begin  // e46==-1
        tree_29 = 2'd3;
      end else begin  // e46==+1
        tree_29 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 30: class 0, round 3
  function automatic [1:0] tree_30;
    input logic [63:0] emb;
  begin
  if (!emb[58]) begin  // e58==-1
    if (!emb[54]) begin  // e54==-1
      if (!emb[62]) begin  // e62==-1
        tree_30 = 2'd3;
      end else begin  // e62==+1
        tree_30 = 2'd1;
      end
    end else begin  // e54==+1
      if (!emb[23]) begin  // e23==-1
        tree_30 = 2'd0;
      end else begin  // e23==+1
        tree_30 = 2'd0;
      end
    end
  end else begin  // e58==+1
    if (!emb[9]) begin  // e9==-1
      if (!emb[16]) begin  // e16==-1
        tree_30 = 2'd1;
      end else begin  // e16==+1
        tree_30 = 2'd3;
      end
    end else begin  // e9==+1
      if (!emb[15]) begin  // e15==-1
        tree_30 = 2'd2;
      end else begin  // e15==+1
        tree_30 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 31: class 1, round 3
  function automatic [1:0] tree_31;
    input logic [63:0] emb;
  begin
  if (!emb[57]) begin  // e57==-1
    if (!emb[39]) begin  // e39==-1
      if (!emb[8]) begin  // e8==-1
        tree_31 = 2'd0;
      end else begin  // e8==+1
        tree_31 = 2'd3;
      end
    end else begin  // e39==+1
      if (!emb[20]) begin  // e20==-1
        tree_31 = 2'd1;
      end else begin  // e20==+1
        tree_31 = 2'd0;
      end
    end
  end else begin  // e57==+1
    if (!emb[42]) begin  // e42==-1
      if (!emb[16]) begin  // e16==-1
        tree_31 = 2'd1;
      end else begin  // e16==+1
        tree_31 = 2'd0;
      end
    end else begin  // e42==+1
      if (!emb[41]) begin  // e41==-1
        tree_31 = 2'd0;
      end else begin  // e41==+1
        tree_31 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 32: class 2, round 3
  function automatic [1:0] tree_32;
    input logic [63:0] emb;
  begin
  if (!emb[19]) begin  // e19==-1
    if (!emb[32]) begin  // e32==-1
      if (!emb[57]) begin  // e57==-1
        tree_32 = 2'd3;
      end else begin  // e57==+1
        tree_32 = 2'd3;
      end
    end else begin  // e32==+1
      if (!emb[13]) begin  // e13==-1
        tree_32 = 2'd3;
      end else begin  // e13==+1
        tree_32 = 2'd2;
      end
    end
  end else begin  // e19==+1
    if (!emb[21]) begin  // e21==-1
      if (!emb[30]) begin  // e30==-1
        tree_32 = 2'd1;
      end else begin  // e30==+1
        tree_32 = 2'd0;
      end
    end else begin  // e21==+1
      if (!emb[0]) begin  // e0==-1
        tree_32 = 2'd0;
      end else begin  // e0==+1
        tree_32 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 33: class 3, round 3
  function automatic [1:0] tree_33;
    input logic [63:0] emb;
  begin
  if (!emb[59]) begin  // e59==-1
    if (!emb[20]) begin  // e20==-1
      if (!emb[13]) begin  // e13==-1
        tree_33 = 2'd3;
      end else begin  // e13==+1
        tree_33 = 2'd2;
      end
    end else begin  // e20==+1
      if (!emb[27]) begin  // e27==-1
        tree_33 = 2'd0;
      end else begin  // e27==+1
        tree_33 = 2'd1;
      end
    end
  end else begin  // e59==+1
    if (!emb[27]) begin  // e27==-1
      if (!emb[24]) begin  // e24==-1
        tree_33 = 2'd1;
      end else begin  // e24==+1
        tree_33 = 2'd2;
      end
    end else begin  // e27==+1
      if (!emb[52]) begin  // e52==-1
        tree_33 = 2'd3;
      end else begin  // e52==+1
        tree_33 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 34: class 4, round 3
  function automatic [1:0] tree_34;
    input logic [63:0] emb;
  begin
  if (!emb[46]) begin  // e46==-1
    if (!emb[3]) begin  // e3==-1
      if (!emb[50]) begin  // e50==-1
        tree_34 = 2'd3;
      end else begin  // e50==+1
        tree_34 = 2'd2;
      end
    end else begin  // e3==+1
      if (!emb[33]) begin  // e33==-1
        tree_34 = 2'd2;
      end else begin  // e33==+1
        tree_34 = 2'd1;
      end
    end
  end else begin  // e46==+1
    if (!emb[50]) begin  // e50==-1
      if (!emb[55]) begin  // e55==-1
        tree_34 = 2'd3;
      end else begin  // e55==+1
        tree_34 = 2'd1;
      end
    end else begin  // e50==+1
      if (!emb[35]) begin  // e35==-1
        tree_34 = 2'd0;
      end else begin  // e35==+1
        tree_34 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 35: class 5, round 3
  function automatic [1:0] tree_35;
    input logic [63:0] emb;
  begin
  if (!emb[0]) begin  // e0==-1
    if (!emb[52]) begin  // e52==-1
      if (!emb[54]) begin  // e54==-1
        tree_35 = 2'd3;
      end else begin  // e54==+1
        tree_35 = 2'd1;
      end
    end else begin  // e52==+1
      if (!emb[26]) begin  // e26==-1
        tree_35 = 2'd3;
      end else begin  // e26==+1
        tree_35 = 2'd3;
      end
    end
  end else begin  // e0==+1
    if (!emb[30]) begin  // e30==-1
      if (!emb[40]) begin  // e40==-1
        tree_35 = 2'd2;
      end else begin  // e40==+1
        tree_35 = 2'd0;
      end
    end else begin  // e30==+1
      if (!emb[28]) begin  // e28==-1
        tree_35 = 2'd0;
      end else begin  // e28==+1
        tree_35 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 36: class 6, round 3
  function automatic [1:0] tree_36;
    input logic [63:0] emb;
  begin
  if (!emb[37]) begin  // e37==-1
    if (!emb[10]) begin  // e10==-1
      if (!emb[35]) begin  // e35==-1
        tree_36 = 2'd3;
      end else begin  // e35==+1
        tree_36 = 2'd2;
      end
    end else begin  // e10==+1
      if (!emb[17]) begin  // e17==-1
        tree_36 = 2'd1;
      end else begin  // e17==+1
        tree_36 = 2'd0;
      end
    end
  end else begin  // e37==+1
    if (!emb[36]) begin  // e36==-1
      if (!emb[47]) begin  // e47==-1
        tree_36 = 2'd1;
      end else begin  // e47==+1
        tree_36 = 2'd0;
      end
    end else begin  // e36==+1
      if (!emb[50]) begin  // e50==-1
        tree_36 = 2'd1;
      end else begin  // e50==+1
        tree_36 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 37: class 7, round 3
  function automatic [1:0] tree_37;
    input logic [63:0] emb;
  begin
  if (!emb[33]) begin  // e33==-1
    if (!emb[56]) begin  // e56==-1
      if (!emb[50]) begin  // e50==-1
        tree_37 = 2'd1;
      end else begin  // e50==+1
        tree_37 = 2'd3;
      end
    end else begin  // e56==+1
      if (!emb[8]) begin  // e8==-1
        tree_37 = 2'd2;
      end else begin  // e8==+1
        tree_37 = 2'd3;
      end
    end
  end else begin  // e33==+1
    if (!emb[39]) begin  // e39==-1
      if (!emb[17]) begin  // e17==-1
        tree_37 = 2'd0;
      end else begin  // e17==+1
        tree_37 = 2'd1;
      end
    end else begin  // e39==+1
      if (!emb[21]) begin  // e21==-1
        tree_37 = 2'd2;
      end else begin  // e21==+1
        tree_37 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 38: class 8, round 3
  function automatic [1:0] tree_38;
    input logic [63:0] emb;
  begin
  if (!emb[40]) begin  // e40==-1
    if (!emb[2]) begin  // e2==-1
      if (!emb[35]) begin  // e35==-1
        tree_38 = 2'd0;
      end else begin  // e35==+1
        tree_38 = 2'd1;
      end
    end else begin  // e2==+1
      if (!emb[23]) begin  // e23==-1
        tree_38 = 2'd0;
      end else begin  // e23==+1
        tree_38 = 2'd2;
      end
    end
  end else begin  // e40==+1
    if (!emb[11]) begin  // e11==-1
      if (!emb[27]) begin  // e27==-1
        tree_38 = 2'd2;
      end else begin  // e27==+1
        tree_38 = 2'd3;
      end
    end else begin  // e11==+1
      if (!emb[31]) begin  // e31==-1
        tree_38 = 2'd2;
      end else begin  // e31==+1
        tree_38 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 39: class 9, round 3
  function automatic [1:0] tree_39;
    input logic [63:0] emb;
  begin
  if (!emb[31]) begin  // e31==-1
    if (!emb[17]) begin  // e17==-1
      if (!emb[48]) begin  // e48==-1
        tree_39 = 2'd0;
      end else begin  // e48==+1
        tree_39 = 2'd2;
      end
    end else begin  // e17==+1
      if (!emb[58]) begin  // e58==-1
        tree_39 = 2'd1;
      end else begin  // e58==+1
        tree_39 = 2'd3;
      end
    end
  end else begin  // e31==+1
    if (!emb[47]) begin  // e47==-1
      if (!emb[5]) begin  // e5==-1
        tree_39 = 2'd1;
      end else begin  // e5==+1
        tree_39 = 2'd2;
      end
    end else begin  // e47==+1
      if (!emb[46]) begin  // e46==-1
        tree_39 = 2'd3;
      end else begin  // e46==+1
        tree_39 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 40: class 0, round 4
  function automatic [1:0] tree_40;
    input logic [63:0] emb;
  begin
  if (!emb[43]) begin  // e43==-1
    if (!emb[59]) begin  // e59==-1
      if (!emb[15]) begin  // e15==-1
        tree_40 = 2'd2;
      end else begin  // e15==+1
        tree_40 = 2'd0;
      end
    end else begin  // e59==+1
      if (!emb[60]) begin  // e60==-1
        tree_40 = 2'd0;
      end else begin  // e60==+1
        tree_40 = 2'd0;
      end
    end
  end else begin  // e43==+1
    if (!emb[33]) begin  // e33==-1
      if (!emb[21]) begin  // e21==-1
        tree_40 = 2'd0;
      end else begin  // e21==+1
        tree_40 = 2'd3;
      end
    end else begin  // e33==+1
      if (!emb[45]) begin  // e45==-1
        tree_40 = 2'd3;
      end else begin  // e45==+1
        tree_40 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 41: class 1, round 4
  function automatic [1:0] tree_41;
    input logic [63:0] emb;
  begin
  if (!emb[24]) begin  // e24==-1
    if (!emb[30]) begin  // e30==-1
      if (!emb[62]) begin  // e62==-1
        tree_41 = 2'd2;
      end else begin  // e62==+1
        tree_41 = 2'd0;
      end
    end else begin  // e30==+1
      if (!emb[62]) begin  // e62==-1
        tree_41 = 2'd0;
      end else begin  // e62==+1
        tree_41 = 2'd0;
      end
    end
  end else begin  // e24==+1
    if (!emb[16]) begin  // e16==-1
      if (!emb[42]) begin  // e42==-1
        tree_41 = 2'd3;
      end else begin  // e42==+1
        tree_41 = 2'd1;
      end
    end else begin  // e16==+1
      if (!emb[33]) begin  // e33==-1
        tree_41 = 2'd1;
      end else begin  // e33==+1
        tree_41 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 42: class 2, round 4
  function automatic [1:0] tree_42;
    input logic [63:0] emb;
  begin
  if (!emb[48]) begin  // e48==-1
    if (!emb[52]) begin  // e52==-1
      if (!emb[0]) begin  // e0==-1
        tree_42 = 2'd2;
      end else begin  // e0==+1
        tree_42 = 2'd3;
      end
    end else begin  // e52==+1
      if (!emb[30]) begin  // e30==-1
        tree_42 = 2'd2;
      end else begin  // e30==+1
        tree_42 = 2'd1;
      end
    end
  end else begin  // e48==+1
    if (!emb[41]) begin  // e41==-1
      if (!emb[22]) begin  // e22==-1
        tree_42 = 2'd2;
      end else begin  // e22==+1
        tree_42 = 2'd0;
      end
    end else begin  // e41==+1
      if (!emb[42]) begin  // e42==-1
        tree_42 = 2'd2;
      end else begin  // e42==+1
        tree_42 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 43: class 3, round 4
  function automatic [1:0] tree_43;
    input logic [63:0] emb;
  begin
  if (!emb[49]) begin  // e49==-1
    if (!emb[25]) begin  // e25==-1
      if (!emb[63]) begin  // e63==-1
        tree_43 = 2'd1;
      end else begin  // e63==+1
        tree_43 = 2'd0;
      end
    end else begin  // e25==+1
      if (!emb[24]) begin  // e24==-1
        tree_43 = 2'd1;
      end else begin  // e24==+1
        tree_43 = 2'd2;
      end
    end
  end else begin  // e49==+1
    if (!emb[18]) begin  // e18==-1
      if (!emb[45]) begin  // e45==-1
        tree_43 = 2'd0;
      end else begin  // e45==+1
        tree_43 = 2'd3;
      end
    end else begin  // e18==+1
      if (!emb[25]) begin  // e25==-1
        tree_43 = 2'd2;
      end else begin  // e25==+1
        tree_43 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 44: class 4, round 4
  function automatic [1:0] tree_44;
    input logic [63:0] emb;
  begin
  if (!emb[33]) begin  // e33==-1
    if (!emb[24]) begin  // e24==-1
      if (!emb[25]) begin  // e25==-1
        tree_44 = 2'd3;
      end else begin  // e25==+1
        tree_44 = 2'd2;
      end
    end else begin  // e24==+1
      if (!emb[62]) begin  // e62==-1
        tree_44 = 2'd1;
      end else begin  // e62==+1
        tree_44 = 2'd2;
      end
    end
  end else begin  // e33==+1
    if (!emb[48]) begin  // e48==-1
      if (!emb[17]) begin  // e17==-1
        tree_44 = 2'd1;
      end else begin  // e17==+1
        tree_44 = 2'd2;
      end
    end else begin  // e48==+1
      if (!emb[57]) begin  // e57==-1
        tree_44 = 2'd3;
      end else begin  // e57==+1
        tree_44 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 45: class 5, round 4
  function automatic [1:0] tree_45;
    input logic [63:0] emb;
  begin
  if (!emb[24]) begin  // e24==-1
    if (!emb[27]) begin  // e27==-1
      if (!emb[62]) begin  // e62==-1
        tree_45 = 2'd2;
      end else begin  // e62==+1
        tree_45 = 2'd0;
      end
    end else begin  // e27==+1
      if (!emb[22]) begin  // e22==-1
        tree_45 = 2'd1;
      end else begin  // e22==+1
        tree_45 = 2'd2;
      end
    end
  end else begin  // e24==+1
    if (!emb[2]) begin  // e2==-1
      if (!emb[43]) begin  // e43==-1
        tree_45 = 2'd2;
      end else begin  // e43==+1
        tree_45 = 2'd3;
      end
    end else begin  // e2==+1
      if (!emb[60]) begin  // e60==-1
        tree_45 = 2'd1;
      end else begin  // e60==+1
        tree_45 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 46: class 6, round 4
  function automatic [1:0] tree_46;
    input logic [63:0] emb;
  begin
  if (!emb[26]) begin  // e26==-1
    if (!emb[50]) begin  // e50==-1
      if (!emb[37]) begin  // e37==-1
        tree_46 = 2'd2;
      end else begin  // e37==+1
        tree_46 = 2'd0;
      end
    end else begin  // e50==+1
      if (!emb[30]) begin  // e30==-1
        tree_46 = 2'd1;
      end else begin  // e30==+1
        tree_46 = 2'd3;
      end
    end
  end else begin  // e26==+1
    if (!emb[36]) begin  // e36==-1
      if (!emb[29]) begin  // e29==-1
        tree_46 = 2'd0;
      end else begin  // e29==+1
        tree_46 = 2'd1;
      end
    end else begin  // e36==+1
      if (!emb[40]) begin  // e40==-1
        tree_46 = 2'd3;
      end else begin  // e40==+1
        tree_46 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 47: class 7, round 4
  function automatic [1:0] tree_47;
    input logic [63:0] emb;
  begin
  if (!emb[10]) begin  // e10==-1
    if (!emb[18]) begin  // e18==-1
      if (!emb[8]) begin  // e8==-1
        tree_47 = 2'd1;
      end else begin  // e8==+1
        tree_47 = 2'd3;
      end
    end else begin  // e18==+1
      if (!emb[47]) begin  // e47==-1
        tree_47 = 2'd0;
      end else begin  // e47==+1
        tree_47 = 2'd1;
      end
    end
  end else begin  // e10==+1
    if (!emb[35]) begin  // e35==-1
      if (!emb[33]) begin  // e33==-1
        tree_47 = 2'd1;
      end else begin  // e33==+1
        tree_47 = 2'd0;
      end
    end else begin  // e35==+1
      if (!emb[29]) begin  // e29==-1
        tree_47 = 2'd3;
      end else begin  // e29==+1
        tree_47 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 48: class 8, round 4
  function automatic [1:0] tree_48;
    input logic [63:0] emb;
  begin
  if (!emb[51]) begin  // e51==-1
    if (!emb[38]) begin  // e38==-1
      if (!emb[0]) begin  // e0==-1
        tree_48 = 2'd2;
      end else begin  // e0==+1
        tree_48 = 2'd1;
      end
    end else begin  // e38==+1
      if (!emb[13]) begin  // e13==-1
        tree_48 = 2'd1;
      end else begin  // e13==+1
        tree_48 = 2'd3;
      end
    end
  end else begin  // e51==+1
    if (!emb[24]) begin  // e24==-1
      if (!emb[52]) begin  // e52==-1
        tree_48 = 2'd0;
      end else begin  // e52==+1
        tree_48 = 2'd1;
      end
    end else begin  // e24==+1
      if (!emb[10]) begin  // e10==-1
        tree_48 = 2'd1;
      end else begin  // e10==+1
        tree_48 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 49: class 9, round 4
  function automatic [1:0] tree_49;
    input logic [63:0] emb;
  begin
  if (!emb[19]) begin  // e19==-1
    if (!emb[48]) begin  // e48==-1
      if (!emb[57]) begin  // e57==-1
        tree_49 = 2'd0;
      end else begin  // e57==+1
        tree_49 = 2'd1;
      end
    end else begin  // e48==+1
      if (!emb[39]) begin  // e39==-1
        tree_49 = 2'd1;
      end else begin  // e39==+1
        tree_49 = 2'd3;
      end
    end
  end else begin  // e19==+1
    if (!emb[17]) begin  // e17==-1
      if (!emb[22]) begin  // e22==-1
        tree_49 = 2'd1;
      end else begin  // e22==+1
        tree_49 = 2'd2;
      end
    end else begin  // e17==+1
      if (!emb[5]) begin  // e5==-1
        tree_49 = 2'd2;
      end else begin  // e5==+1
        tree_49 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 50: class 0, round 5
  function automatic [1:0] tree_50;
    input logic [63:0] emb;
  begin
  if (!emb[3]) begin  // e3==-1
    if (!emb[5]) begin  // e5==-1
      if (!emb[42]) begin  // e42==-1
        tree_50 = 2'd0;
      end else begin  // e42==+1
        tree_50 = 2'd1;
      end
    end else begin  // e5==+1
      if (!emb[61]) begin  // e61==-1
        tree_50 = 2'd2;
      end else begin  // e61==+1
        tree_50 = 2'd0;
      end
    end
  end else begin  // e3==+1
    if (!emb[36]) begin  // e36==-1
      if (!emb[43]) begin  // e43==-1
        tree_50 = 2'd1;
      end else begin  // e43==+1
        tree_50 = 2'd2;
      end
    end else begin  // e36==+1
      if (!emb[55]) begin  // e55==-1
        tree_50 = 2'd1;
      end else begin  // e55==+1
        tree_50 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 51: class 1, round 5
  function automatic [1:0] tree_51;
    input logic [63:0] emb;
  begin
  if (!emb[63]) begin  // e63==-1
    if (!emb[45]) begin  // e45==-1
      if (!emb[62]) begin  // e62==-1
        tree_51 = 2'd0;
      end else begin  // e62==+1
        tree_51 = 2'd0;
      end
    end else begin  // e45==+1
      if (!emb[43]) begin  // e43==-1
        tree_51 = 2'd0;
      end else begin  // e43==+1
        tree_51 = 2'd3;
      end
    end
  end else begin  // e63==+1
    if (!emb[39]) begin  // e39==-1
      if (!emb[57]) begin  // e57==-1
        tree_51 = 2'd3;
      end else begin  // e57==+1
        tree_51 = 2'd1;
      end
    end else begin  // e39==+1
      if (!emb[20]) begin  // e20==-1
        tree_51 = 2'd2;
      end else begin  // e20==+1
        tree_51 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 52: class 2, round 5
  function automatic [1:0] tree_52;
    input logic [63:0] emb;
  begin
  if (!emb[50]) begin  // e50==-1
    if (!emb[21]) begin  // e21==-1
      if (!emb[8]) begin  // e8==-1
        tree_52 = 2'd1;
      end else begin  // e8==+1
        tree_52 = 2'd0;
      end
    end else begin  // e21==+1
      if (!emb[36]) begin  // e36==-1
        tree_52 = 2'd2;
      end else begin  // e36==+1
        tree_52 = 2'd1;
      end
    end
  end else begin  // e50==+1
    if (!emb[55]) begin  // e55==-1
      if (!emb[24]) begin  // e24==-1
        tree_52 = 2'd0;
      end else begin  // e24==+1
        tree_52 = 2'd2;
      end
    end else begin  // e55==+1
      if (!emb[43]) begin  // e43==-1
        tree_52 = 2'd3;
      end else begin  // e43==+1
        tree_52 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 53: class 3, round 5
  function automatic [1:0] tree_53;
    input logic [63:0] emb;
  begin
  if (!emb[42]) begin  // e42==-1
    if (!emb[20]) begin  // e20==-1
      if (!emb[37]) begin  // e37==-1
        tree_53 = 2'd3;
      end else begin  // e37==+1
        tree_53 = 2'd3;
      end
    end else begin  // e20==+1
      if (!emb[22]) begin  // e22==-1
        tree_53 = 2'd1;
      end else begin  // e22==+1
        tree_53 = 2'd2;
      end
    end
  end else begin  // e42==+1
    if (!emb[37]) begin  // e37==-1
      if (!emb[41]) begin  // e41==-1
        tree_53 = 2'd1;
      end else begin  // e41==+1
        tree_53 = 2'd0;
      end
    end else begin  // e37==+1
      if (!emb[46]) begin  // e46==-1
        tree_53 = 2'd1;
      end else begin  // e46==+1
        tree_53 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 54: class 4, round 5
  function automatic [1:0] tree_54;
    input logic [63:0] emb;
  begin
  if (!emb[43]) begin  // e43==-1
    if (!emb[44]) begin  // e44==-1
      if (!emb[53]) begin  // e53==-1
        tree_54 = 2'd2;
      end else begin  // e53==+1
        tree_54 = 2'd3;
      end
    end else begin  // e44==+1
      if (!emb[51]) begin  // e51==-1
        tree_54 = 2'd1;
      end else begin  // e51==+1
        tree_54 = 2'd2;
      end
    end
  end else begin  // e43==+1
    if (!emb[35]) begin  // e35==-1
      if (!emb[3]) begin  // e3==-1
        tree_54 = 2'd3;
      end else begin  // e3==+1
        tree_54 = 2'd1;
      end
    end else begin  // e35==+1
      if (!emb[39]) begin  // e39==-1
        tree_54 = 2'd0;
      end else begin  // e39==+1
        tree_54 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 55: class 5, round 5
  function automatic [1:0] tree_55;
    input logic [63:0] emb;
  begin
  if (!emb[35]) begin  // e35==-1
    if (!emb[58]) begin  // e58==-1
      if (!emb[62]) begin  // e62==-1
        tree_55 = 2'd2;
      end else begin  // e62==+1
        tree_55 = 2'd1;
      end
    end else begin  // e58==+1
      if (!emb[5]) begin  // e5==-1
        tree_55 = 2'd3;
      end else begin  // e5==+1
        tree_55 = 2'd1;
      end
    end
  end else begin  // e35==+1
    if (!emb[25]) begin  // e25==-1
      if (!emb[9]) begin  // e9==-1
        tree_55 = 2'd2;
      end else begin  // e9==+1
        tree_55 = 2'd3;
      end
    end else begin  // e25==+1
      if (!emb[54]) begin  // e54==-1
        tree_55 = 2'd3;
      end else begin  // e54==+1
        tree_55 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 56: class 6, round 5
  function automatic [1:0] tree_56;
    input logic [63:0] emb;
  begin
  if (!emb[47]) begin  // e47==-1
    if (!emb[20]) begin  // e20==-1
      if (!emb[57]) begin  // e57==-1
        tree_56 = 2'd2;
      end else begin  // e57==+1
        tree_56 = 2'd0;
      end
    end else begin  // e20==+1
      if (!emb[25]) begin  // e25==-1
        tree_56 = 2'd3;
      end else begin  // e25==+1
        tree_56 = 2'd2;
      end
    end
  end else begin  // e47==+1
    if (!emb[63]) begin  // e63==-1
      if (!emb[35]) begin  // e35==-1
        tree_56 = 2'd3;
      end else begin  // e35==+1
        tree_56 = 2'd1;
      end
    end else begin  // e63==+1
      if (!emb[52]) begin  // e52==-1
        tree_56 = 2'd0;
      end else begin  // e52==+1
        tree_56 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 57: class 7, round 5
  function automatic [1:0] tree_57;
    input logic [63:0] emb;
  begin
  if (!emb[33]) begin  // e33==-1
    if (!emb[30]) begin  // e30==-1
      if (!emb[17]) begin  // e17==-1
        tree_57 = 2'd2;
      end else begin  // e17==+1
        tree_57 = 2'd3;
      end
    end else begin  // e30==+1
      if (!emb[50]) begin  // e50==-1
        tree_57 = 2'd1;
      end else begin  // e50==+1
        tree_57 = 2'd3;
      end
    end
  end else begin  // e33==+1
    if (!emb[45]) begin  // e45==-1
      if (!emb[21]) begin  // e21==-1
        tree_57 = 2'd2;
      end else begin  // e21==+1
        tree_57 = 2'd0;
      end
    end else begin  // e45==+1
      if (!emb[24]) begin  // e24==-1
        tree_57 = 2'd1;
      end else begin  // e24==+1
        tree_57 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 58: class 8, round 5
  function automatic [1:0] tree_58;
    input logic [63:0] emb;
  begin
  if (!emb[18]) begin  // e18==-1
    if (!emb[44]) begin  // e44==-1
      if (!emb[52]) begin  // e52==-1
        tree_58 = 2'd0;
      end else begin  // e52==+1
        tree_58 = 2'd0;
      end
    end else begin  // e44==+1
      if (!emb[50]) begin  // e50==-1
        tree_58 = 2'd3;
      end else begin  // e50==+1
        tree_58 = 2'd0;
      end
    end
  end else begin  // e18==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[28]) begin  // e28==-1
        tree_58 = 2'd2;
      end else begin  // e28==+1
        tree_58 = 2'd1;
      end
    end else begin  // e19==+1
      if (!emb[61]) begin  // e61==-1
        tree_58 = 2'd3;
      end else begin  // e61==+1
        tree_58 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 59: class 9, round 5
  function automatic [1:0] tree_59;
    input logic [63:0] emb;
  begin
  if (!emb[39]) begin  // e39==-1
    if (!emb[47]) begin  // e47==-1
      if (!emb[35]) begin  // e35==-1
        tree_59 = 2'd1;
      end else begin  // e35==+1
        tree_59 = 2'd0;
      end
    end else begin  // e47==+1
      if (!emb[52]) begin  // e52==-1
        tree_59 = 2'd1;
      end else begin  // e52==+1
        tree_59 = 2'd3;
      end
    end
  end else begin  // e39==+1
    if (!emb[25]) begin  // e25==-1
      if (!emb[53]) begin  // e53==-1
        tree_59 = 2'd2;
      end else begin  // e53==+1
        tree_59 = 2'd1;
      end
    end else begin  // e25==+1
      if (!emb[60]) begin  // e60==-1
        tree_59 = 2'd3;
      end else begin  // e60==+1
        tree_59 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 60: class 0, round 6
  function automatic [1:0] tree_60;
    input logic [63:0] emb;
  begin
  if (!emb[58]) begin  // e58==-1
    if (!emb[26]) begin  // e26==-1
      if (!emb[43]) begin  // e43==-1
        tree_60 = 2'd1;
      end else begin  // e43==+1
        tree_60 = 2'd3;
      end
    end else begin  // e26==+1
      if (!emb[11]) begin  // e11==-1
        tree_60 = 2'd1;
      end else begin  // e11==+1
        tree_60 = 2'd0;
      end
    end
  end else begin  // e58==+1
    if (!emb[33]) begin  // e33==-1
      if (!emb[21]) begin  // e21==-1
        tree_60 = 2'd0;
      end else begin  // e21==+1
        tree_60 = 2'd3;
      end
    end else begin  // e33==+1
      if (!emb[45]) begin  // e45==-1
        tree_60 = 2'd3;
      end else begin  // e45==+1
        tree_60 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 61: class 1, round 6
  function automatic [1:0] tree_61;
    input logic [63:0] emb;
  begin
  if (!emb[58]) begin  // e58==-1
    if (!emb[26]) begin  // e26==-1
      if (!emb[35]) begin  // e35==-1
        tree_61 = 2'd0;
      end else begin  // e35==+1
        tree_61 = 2'd2;
      end
    end else begin  // e26==+1
      if (!emb[50]) begin  // e50==-1
        tree_61 = 2'd3;
      end else begin  // e50==+1
        tree_61 = 2'd2;
      end
    end
  end else begin  // e58==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[28]) begin  // e28==-1
        tree_61 = 2'd2;
      end else begin  // e28==+1
        tree_61 = 2'd0;
      end
    end else begin  // e19==+1
      if (!emb[0]) begin  // e0==-1
        tree_61 = 2'd1;
      end else begin  // e0==+1
        tree_61 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 62: class 2, round 6
  function automatic [1:0] tree_62;
    input logic [63:0] emb;
  begin
  if (!emb[16]) begin  // e16==-1
    if (!emb[15]) begin  // e15==-1
      if (!emb[52]) begin  // e52==-1
        tree_62 = 2'd3;
      end else begin  // e52==+1
        tree_62 = 2'd2;
      end
    end else begin  // e15==+1
      if (!emb[14]) begin  // e14==-1
        tree_62 = 2'd1;
      end else begin  // e14==+1
        tree_62 = 2'd2;
      end
    end
  end else begin  // e16==+1
    if (!emb[22]) begin  // e22==-1
      if (!emb[50]) begin  // e50==-1
        tree_62 = 2'd1;
      end else begin  // e50==+1
        tree_62 = 2'd3;
      end
    end else begin  // e22==+1
      if (!emb[1]) begin  // e1==-1
        tree_62 = 2'd1;
      end else begin  // e1==+1
        tree_62 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 63: class 3, round 6
  function automatic [1:0] tree_63;
    input logic [63:0] emb;
  begin
  if (!emb[3]) begin  // e3==-1
    if (!emb[16]) begin  // e16==-1
      if (!emb[5]) begin  // e5==-1
        tree_63 = 2'd1;
      end else begin  // e5==+1
        tree_63 = 2'd2;
      end
    end else begin  // e16==+1
      if (!emb[36]) begin  // e36==-1
        tree_63 = 2'd3;
      end else begin  // e36==+1
        tree_63 = 2'd2;
      end
    end
  end else begin  // e3==+1
    if (!emb[13]) begin  // e13==-1
      if (!emb[39]) begin  // e39==-1
        tree_63 = 2'd3;
      end else begin  // e39==+1
        tree_63 = 2'd1;
      end
    end else begin  // e13==+1
      if (!emb[63]) begin  // e63==-1
        tree_63 = 2'd2;
      end else begin  // e63==+1
        tree_63 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 64: class 4, round 6
  function automatic [1:0] tree_64;
    input logic [63:0] emb;
  begin
  if (!emb[20]) begin  // e20==-1
    if (!emb[42]) begin  // e42==-1
      if (!emb[15]) begin  // e15==-1
        tree_64 = 2'd0;
      end else begin  // e15==+1
        tree_64 = 2'd1;
      end
    end else begin  // e42==+1
      if (!emb[9]) begin  // e9==-1
        tree_64 = 2'd1;
      end else begin  // e9==+1
        tree_64 = 2'd2;
      end
    end
  end else begin  // e20==+1
    if (!emb[54]) begin  // e54==-1
      if (!emb[9]) begin  // e9==-1
        tree_64 = 2'd1;
      end else begin  // e9==+1
        tree_64 = 2'd2;
      end
    end else begin  // e54==+1
      if (!emb[35]) begin  // e35==-1
        tree_64 = 2'd3;
      end else begin  // e35==+1
        tree_64 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 65: class 5, round 6
  function automatic [1:0] tree_65;
    input logic [63:0] emb;
  begin
  if (!emb[0]) begin  // e0==-1
    if (!emb[27]) begin  // e27==-1
      if (!emb[59]) begin  // e59==-1
        tree_65 = 2'd3;
      end else begin  // e59==+1
        tree_65 = 2'd1;
      end
    end else begin  // e27==+1
      if (!emb[26]) begin  // e26==-1
        tree_65 = 2'd2;
      end else begin  // e26==+1
        tree_65 = 2'd3;
      end
    end
  end else begin  // e0==+1
    if (!emb[53]) begin  // e53==-1
      if (!emb[39]) begin  // e39==-1
        tree_65 = 2'd1;
      end else begin  // e39==+1
        tree_65 = 2'd3;
      end
    end else begin  // e53==+1
      if (!emb[41]) begin  // e41==-1
        tree_65 = 2'd1;
      end else begin  // e41==+1
        tree_65 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 66: class 6, round 6
  function automatic [1:0] tree_66;
    input logic [63:0] emb;
  begin
  if (!emb[21]) begin  // e21==-1
    if (!emb[35]) begin  // e35==-1
      if (!emb[25]) begin  // e25==-1
        tree_66 = 2'd2;
      end else begin  // e25==+1
        tree_66 = 2'd1;
      end
    end else begin  // e35==+1
      if (!emb[59]) begin  // e59==-1
        tree_66 = 2'd1;
      end else begin  // e59==+1
        tree_66 = 2'd0;
      end
    end
  end else begin  // e21==+1
    if (!emb[55]) begin  // e55==-1
      if (!emb[63]) begin  // e63==-1
        tree_66 = 2'd3;
      end else begin  // e63==+1
        tree_66 = 2'd2;
      end
    end else begin  // e55==+1
      if (!emb[45]) begin  // e45==-1
        tree_66 = 2'd1;
      end else begin  // e45==+1
        tree_66 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 67: class 7, round 6
  function automatic [1:0] tree_67;
    input logic [63:0] emb;
  begin
  if (!emb[45]) begin  // e45==-1
    if (!emb[35]) begin  // e35==-1
      if (!emb[47]) begin  // e47==-1
        tree_67 = 2'd1;
      end else begin  // e47==+1
        tree_67 = 2'd2;
      end
    end else begin  // e35==+1
      if (!emb[63]) begin  // e63==-1
        tree_67 = 2'd2;
      end else begin  // e63==+1
        tree_67 = 2'd3;
      end
    end
  end else begin  // e45==+1
    if (!emb[11]) begin  // e11==-1
      if (!emb[61]) begin  // e61==-1
        tree_67 = 2'd1;
      end else begin  // e61==+1
        tree_67 = 2'd0;
      end
    end else begin  // e11==+1
      if (!emb[25]) begin  // e25==-1
        tree_67 = 2'd1;
      end else begin  // e25==+1
        tree_67 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 68: class 8, round 6
  function automatic [1:0] tree_68;
    input logic [63:0] emb;
  begin
  if (!emb[24]) begin  // e24==-1
    if (!emb[16]) begin  // e16==-1
      if (!emb[62]) begin  // e62==-1
        tree_68 = 2'd1;
      end else begin  // e62==+1
        tree_68 = 2'd0;
      end
    end else begin  // e16==+1
      if (!emb[44]) begin  // e44==-1
        tree_68 = 2'd1;
      end else begin  // e44==+1
        tree_68 = 2'd2;
      end
    end
  end else begin  // e24==+1
    if (!emb[53]) begin  // e53==-1
      if (!emb[2]) begin  // e2==-1
        tree_68 = 2'd1;
      end else begin  // e2==+1
        tree_68 = 2'd2;
      end
    end else begin  // e53==+1
      if (!emb[59]) begin  // e59==-1
        tree_68 = 2'd3;
      end else begin  // e59==+1
        tree_68 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 69: class 9, round 6
  function automatic [1:0] tree_69;
    input logic [63:0] emb;
  begin
  if (!emb[43]) begin  // e43==-1
    if (!emb[44]) begin  // e44==-1
      if (!emb[57]) begin  // e57==-1
        tree_69 = 2'd2;
      end else begin  // e57==+1
        tree_69 = 2'd3;
      end
    end else begin  // e44==+1
      if (!emb[22]) begin  // e22==-1
        tree_69 = 2'd0;
      end else begin  // e22==+1
        tree_69 = 2'd1;
      end
    end
  end else begin  // e43==+1
    if (!emb[25]) begin  // e25==-1
      if (!emb[29]) begin  // e29==-1
        tree_69 = 2'd1;
      end else begin  // e29==+1
        tree_69 = 2'd0;
      end
    end else begin  // e25==+1
      if (!emb[35]) begin  // e35==-1
        tree_69 = 2'd3;
      end else begin  // e35==+1
        tree_69 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 70: class 0, round 7
  function automatic [1:0] tree_70;
    input logic [63:0] emb;
  begin
  if (!emb[38]) begin  // e38==-1
    if (!emb[52]) begin  // e52==-1
      if (!emb[11]) begin  // e11==-1
        tree_70 = 2'd0;
      end else begin  // e11==+1
        tree_70 = 2'd0;
      end
    end else begin  // e52==+1
      if (!emb[15]) begin  // e15==-1
        tree_70 = 2'd2;
      end else begin  // e15==+1
        tree_70 = 2'd0;
      end
    end
  end else begin  // e38==+1
    if (!emb[9]) begin  // e9==-1
      if (!emb[62]) begin  // e62==-1
        tree_70 = 2'd3;
      end else begin  // e62==+1
        tree_70 = 2'd2;
      end
    end else begin  // e9==+1
      if (!emb[20]) begin  // e20==-1
        tree_70 = 2'd2;
      end else begin  // e20==+1
        tree_70 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 71: class 1, round 7
  function automatic [1:0] tree_71;
    input logic [63:0] emb;
  begin
  if (!emb[4]) begin  // e4==-1
    if (!emb[46]) begin  // e46==-1
      if (!emb[28]) begin  // e28==-1
        tree_71 = 2'd0;
      end else begin  // e28==+1
        tree_71 = 2'd0;
      end
    end else begin  // e46==+1
      if (!emb[1]) begin  // e1==-1
        tree_71 = 2'd1;
      end else begin  // e1==+1
        tree_71 = 2'd0;
      end
    end
  end else begin  // e4==+1
    if (!emb[32]) begin  // e32==-1
      if (!emb[56]) begin  // e56==-1
        tree_71 = 2'd3;
      end else begin  // e56==+1
        tree_71 = 2'd0;
      end
    end else begin  // e32==+1
      if (!emb[10]) begin  // e10==-1
        tree_71 = 2'd1;
      end else begin  // e10==+1
        tree_71 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 72: class 2, round 7
  function automatic [1:0] tree_72;
    input logic [63:0] emb;
  begin
  if (!emb[3]) begin  // e3==-1
    if (!emb[56]) begin  // e56==-1
      if (!emb[5]) begin  // e5==-1
        tree_72 = 2'd1;
      end else begin  // e5==+1
        tree_72 = 2'd1;
      end
    end else begin  // e56==+1
      if (!emb[45]) begin  // e45==-1
        tree_72 = 2'd2;
      end else begin  // e45==+1
        tree_72 = 2'd3;
      end
    end
  end else begin  // e3==+1
    if (!emb[48]) begin  // e48==-1
      if (!emb[32]) begin  // e32==-1
        tree_72 = 2'd3;
      end else begin  // e32==+1
        tree_72 = 2'd2;
      end
    end else begin  // e48==+1
      if (!emb[1]) begin  // e1==-1
        tree_72 = 2'd2;
      end else begin  // e1==+1
        tree_72 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 73: class 3, round 7
  function automatic [1:0] tree_73;
    input logic [63:0] emb;
  begin
  if (!emb[35]) begin  // e35==-1
    if (!emb[4]) begin  // e4==-1
      if (!emb[44]) begin  // e44==-1
        tree_73 = 2'd0;
      end else begin  // e44==+1
        tree_73 = 2'd1;
      end
    end else begin  // e4==+1
      if (!emb[44]) begin  // e44==-1
        tree_73 = 2'd1;
      end else begin  // e44==+1
        tree_73 = 2'd2;
      end
    end
  end else begin  // e35==+1
    if (!emb[49]) begin  // e49==-1
      if (!emb[30]) begin  // e30==-1
        tree_73 = 2'd1;
      end else begin  // e30==+1
        tree_73 = 2'd2;
      end
    end else begin  // e49==+1
      if (!emb[13]) begin  // e13==-1
        tree_73 = 2'd3;
      end else begin  // e13==+1
        tree_73 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 74: class 4, round 7
  function automatic [1:0] tree_74;
    input logic [63:0] emb;
  begin
  if (!emb[61]) begin  // e61==-1
    if (!emb[58]) begin  // e58==-1
      if (!emb[46]) begin  // e46==-1
        tree_74 = 2'd2;
      end else begin  // e46==+1
        tree_74 = 2'd1;
      end
    end else begin  // e58==+1
      if (!emb[29]) begin  // e29==-1
        tree_74 = 2'd2;
      end else begin  // e29==+1
        tree_74 = 2'd1;
      end
    end
  end else begin  // e61==+1
    if (!emb[9]) begin  // e9==-1
      if (!emb[31]) begin  // e31==-1
        tree_74 = 2'd1;
      end else begin  // e31==+1
        tree_74 = 2'd2;
      end
    end else begin  // e9==+1
      if (!emb[55]) begin  // e55==-1
        tree_74 = 2'd3;
      end else begin  // e55==+1
        tree_74 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 75: class 5, round 7
  function automatic [1:0] tree_75;
    input logic [63:0] emb;
  begin
  if (!emb[18]) begin  // e18==-1
    if (!emb[59]) begin  // e59==-1
      if (!emb[37]) begin  // e37==-1
        tree_75 = 2'd0;
      end else begin  // e37==+1
        tree_75 = 2'd0;
      end
    end else begin  // e59==+1
      if (!emb[54]) begin  // e54==-1
        tree_75 = 2'd3;
      end else begin  // e54==+1
        tree_75 = 2'd0;
      end
    end
  end else begin  // e18==+1
    if (!emb[28]) begin  // e28==-1
      if (!emb[1]) begin  // e1==-1
        tree_75 = 2'd1;
      end else begin  // e1==+1
        tree_75 = 2'd2;
      end
    end else begin  // e28==+1
      if (!emb[20]) begin  // e20==-1
        tree_75 = 2'd2;
      end else begin  // e20==+1
        tree_75 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 76: class 6, round 7
  function automatic [1:0] tree_76;
    input logic [63:0] emb;
  begin
  if (!emb[40]) begin  // e40==-1
    if (!emb[58]) begin  // e58==-1
      if (!emb[47]) begin  // e47==-1
        tree_76 = 2'd2;
      end else begin  // e47==+1
        tree_76 = 2'd0;
      end
    end else begin  // e58==+1
      if (!emb[25]) begin  // e25==-1
        tree_76 = 2'd3;
      end else begin  // e25==+1
        tree_76 = 2'd2;
      end
    end
  end else begin  // e40==+1
    if (!emb[55]) begin  // e55==-1
      if (!emb[50]) begin  // e50==-1
        tree_76 = 2'd1;
      end else begin  // e50==+1
        tree_76 = 2'd3;
      end
    end else begin  // e55==+1
      if (!emb[54]) begin  // e54==-1
        tree_76 = 2'd2;
      end else begin  // e54==+1
        tree_76 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 77: class 7, round 7
  function automatic [1:0] tree_77;
    input logic [63:0] emb;
  begin
  if (!emb[47]) begin  // e47==-1
    if (!emb[19]) begin  // e19==-1
      if (!emb[39]) begin  // e39==-1
        tree_77 = 2'd0;
      end else begin  // e39==+1
        tree_77 = 2'd1;
      end
    end else begin  // e19==+1
      if (!emb[11]) begin  // e11==-1
        tree_77 = 2'd1;
      end else begin  // e11==+1
        tree_77 = 2'd2;
      end
    end
  end else begin  // e47==+1
    if (!emb[24]) begin  // e24==-1
      if (!emb[40]) begin  // e40==-1
        tree_77 = 2'd3;
      end else begin  // e40==+1
        tree_77 = 2'd2;
      end
    end else begin  // e24==+1
      if (!emb[54]) begin  // e54==-1
        tree_77 = 2'd0;
      end else begin  // e54==+1
        tree_77 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 78: class 8, round 7
  function automatic [1:0] tree_78;
    input logic [63:0] emb;
  begin
  if (!emb[56]) begin  // e56==-1
    if (!emb[20]) begin  // e20==-1
      if (!emb[37]) begin  // e37==-1
        tree_78 = 2'd3;
      end else begin  // e37==+1
        tree_78 = 2'd2;
      end
    end else begin  // e20==+1
      if (!emb[28]) begin  // e28==-1
        tree_78 = 2'd2;
      end else begin  // e28==+1
        tree_78 = 2'd1;
      end
    end
  end else begin  // e56==+1
    if (!emb[50]) begin  // e50==-1
      if (!emb[0]) begin  // e0==-1
        tree_78 = 2'd3;
      end else begin  // e0==+1
        tree_78 = 2'd1;
      end
    end else begin  // e50==+1
      if (!emb[15]) begin  // e15==-1
        tree_78 = 2'd0;
      end else begin  // e15==+1
        tree_78 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 79: class 9, round 7
  function automatic [1:0] tree_79;
    input logic [63:0] emb;
  begin
  if (!emb[17]) begin  // e17==-1
    if (!emb[4]) begin  // e4==-1
      if (!emb[37]) begin  // e37==-1
        tree_79 = 2'd1;
      end else begin  // e37==+1
        tree_79 = 2'd3;
      end
    end else begin  // e4==+1
      if (!emb[8]) begin  // e8==-1
        tree_79 = 2'd1;
      end else begin  // e8==+1
        tree_79 = 2'd2;
      end
    end
  end else begin  // e17==+1
    if (!emb[50]) begin  // e50==-1
      if (!emb[52]) begin  // e52==-1
        tree_79 = 2'd2;
      end else begin  // e52==+1
        tree_79 = 2'd3;
      end
    end else begin  // e50==+1
      if (!emb[22]) begin  // e22==-1
        tree_79 = 2'd1;
      end else begin  // e22==+1
        tree_79 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 80: class 0, round 8
  function automatic [1:0] tree_80;
    input logic [63:0] emb;
  begin
  if (!emb[55]) begin  // e55==-1
    if (!emb[57]) begin  // e57==-1
      if (!emb[16]) begin  // e16==-1
        tree_80 = 2'd1;
      end else begin  // e16==+1
        tree_80 = 2'd0;
      end
    end else begin  // e57==+1
      if (!emb[44]) begin  // e44==-1
        tree_80 = 2'd1;
      end else begin  // e44==+1
        tree_80 = 2'd2;
      end
    end
  end else begin  // e55==+1
    if (!emb[54]) begin  // e54==-1
      if (!emb[59]) begin  // e59==-1
        tree_80 = 2'd3;
      end else begin  // e59==+1
        tree_80 = 2'd1;
      end
    end else begin  // e54==+1
      if (!emb[23]) begin  // e23==-1
        tree_80 = 2'd1;
      end else begin  // e23==+1
        tree_80 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 81: class 1, round 8
  function automatic [1:0] tree_81;
    input logic [63:0] emb;
  begin
  if (!emb[24]) begin  // e24==-1
    if (!emb[41]) begin  // e41==-1
      if (!emb[59]) begin  // e59==-1
        tree_81 = 2'd0;
      end else begin  // e59==+1
        tree_81 = 2'd0;
      end
    end else begin  // e41==+1
      if (!emb[30]) begin  // e30==-1
        tree_81 = 2'd3;
      end else begin  // e30==+1
        tree_81 = 2'd0;
      end
    end
  end else begin  // e24==+1
    if (!emb[27]) begin  // e27==-1
      if (!emb[50]) begin  // e50==-1
        tree_81 = 2'd3;
      end else begin  // e50==+1
        tree_81 = 2'd2;
      end
    end else begin  // e27==+1
      if (!emb[32]) begin  // e32==-1
        tree_81 = 2'd2;
      end else begin  // e32==+1
        tree_81 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 82: class 2, round 8
  function automatic [1:0] tree_82;
    input logic [63:0] emb;
  begin
  if (!emb[9]) begin  // e9==-1
    if (!emb[41]) begin  // e41==-1
      if (!emb[22]) begin  // e22==-1
        tree_82 = 2'd3;
      end else begin  // e22==+1
        tree_82 = 2'd2;
      end
    end else begin  // e41==+1
      if (!emb[10]) begin  // e10==-1
        tree_82 = 2'd3;
      end else begin  // e10==+1
        tree_82 = 2'd2;
      end
    end
  end else begin  // e9==+1
    if (!emb[30]) begin  // e30==-1
      if (!emb[3]) begin  // e3==-1
        tree_82 = 2'd1;
      end else begin  // e3==+1
        tree_82 = 2'd2;
      end
    end else begin  // e30==+1
      if (!emb[60]) begin  // e60==-1
        tree_82 = 2'd1;
      end else begin  // e60==+1
        tree_82 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 83: class 3, round 8
  function automatic [1:0] tree_83;
    input logic [63:0] emb;
  begin
  if (!emb[18]) begin  // e18==-1
    if (!emb[53]) begin  // e53==-1
      if (!emb[54]) begin  // e54==-1
        tree_83 = 2'd3;
      end else begin  // e54==+1
        tree_83 = 2'd1;
      end
    end else begin  // e53==+1
      if (!emb[26]) begin  // e26==-1
        tree_83 = 2'd0;
      end else begin  // e26==+1
        tree_83 = 2'd1;
      end
    end
  end else begin  // e18==+1
    if (!emb[23]) begin  // e23==-1
      if (!emb[1]) begin  // e1==-1
        tree_83 = 2'd3;
      end else begin  // e1==+1
        tree_83 = 2'd2;
      end
    end else begin  // e23==+1
      if (!emb[42]) begin  // e42==-1
        tree_83 = 2'd2;
      end else begin  // e42==+1
        tree_83 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 84: class 4, round 8
  function automatic [1:0] tree_84;
    input logic [63:0] emb;
  begin
  if (!emb[16]) begin  // e16==-1
    if (!emb[9]) begin  // e9==-1
      if (!emb[50]) begin  // e50==-1
        tree_84 = 2'd2;
      end else begin  // e50==+1
        tree_84 = 2'd1;
      end
    end else begin  // e9==+1
      if (!emb[47]) begin  // e47==-1
        tree_84 = 2'd3;
      end else begin  // e47==+1
        tree_84 = 2'd2;
      end
    end
  end else begin  // e16==+1
    if (!emb[27]) begin  // e27==-1
      if (!emb[3]) begin  // e3==-1
        tree_84 = 2'd2;
      end else begin  // e3==+1
        tree_84 = 2'd2;
      end
    end else begin  // e27==+1
      if (!emb[2]) begin  // e2==-1
        tree_84 = 2'd1;
      end else begin  // e2==+1
        tree_84 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 85: class 5, round 8
  function automatic [1:0] tree_85;
    input logic [63:0] emb;
  begin
  if (!emb[17]) begin  // e17==-1
    if (!emb[52]) begin  // e52==-1
      if (!emb[62]) begin  // e62==-1
        tree_85 = 2'd3;
      end else begin  // e62==+1
        tree_85 = 2'd2;
      end
    end else begin  // e52==+1
      if (!emb[60]) begin  // e60==-1
        tree_85 = 2'd2;
      end else begin  // e60==+1
        tree_85 = 2'd3;
      end
    end
  end else begin  // e17==+1
    if (!emb[36]) begin  // e36==-1
      if (!emb[62]) begin  // e62==-1
        tree_85 = 2'd2;
      end else begin  // e62==+1
        tree_85 = 2'd1;
      end
    end else begin  // e36==+1
      if (!emb[4]) begin  // e4==-1
        tree_85 = 2'd1;
      end else begin  // e4==+1
        tree_85 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 86: class 6, round 8
  function automatic [1:0] tree_86;
    input logic [63:0] emb;
  begin
  if (!emb[57]) begin  // e57==-1
    if (!emb[3]) begin  // e3==-1
      if (!emb[63]) begin  // e63==-1
        tree_86 = 2'd3;
      end else begin  // e63==+1
        tree_86 = 2'd2;
      end
    end else begin  // e3==+1
      if (!emb[61]) begin  // e61==-1
        tree_86 = 2'd2;
      end else begin  // e61==+1
        tree_86 = 2'd0;
      end
    end
  end else begin  // e57==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[58]) begin  // e58==-1
        tree_86 = 2'd1;
      end else begin  // e58==+1
        tree_86 = 2'd2;
      end
    end else begin  // e19==+1
      if (!emb[8]) begin  // e8==-1
        tree_86 = 2'd1;
      end else begin  // e8==+1
        tree_86 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 87: class 7, round 8
  function automatic [1:0] tree_87;
    input logic [63:0] emb;
  begin
  if (!emb[19]) begin  // e19==-1
    if (!emb[28]) begin  // e28==-1
      if (!emb[17]) begin  // e17==-1
        tree_87 = 2'd1;
      end else begin  // e17==+1
        tree_87 = 2'd3;
      end
    end else begin  // e28==+1
      if (!emb[31]) begin  // e31==-1
        tree_87 = 2'd0;
      end else begin  // e31==+1
        tree_87 = 2'd2;
      end
    end
  end else begin  // e19==+1
    if (!emb[56]) begin  // e56==-1
      if (!emb[47]) begin  // e47==-1
        tree_87 = 2'd1;
      end else begin  // e47==+1
        tree_87 = 2'd2;
      end
    end else begin  // e56==+1
      if (!emb[54]) begin  // e54==-1
        tree_87 = 2'd2;
      end else begin  // e54==+1
        tree_87 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 88: class 8, round 8
  function automatic [1:0] tree_88;
    input logic [63:0] emb;
  begin
  if (!emb[13]) begin  // e13==-1
    if (!emb[58]) begin  // e58==-1
      if (!emb[44]) begin  // e44==-1
        tree_88 = 2'd0;
      end else begin  // e44==+1
        tree_88 = 2'd1;
      end
    end else begin  // e58==+1
      if (!emb[17]) begin  // e17==-1
        tree_88 = 2'd1;
      end else begin  // e17==+1
        tree_88 = 2'd3;
      end
    end
  end else begin  // e13==+1
    if (!emb[30]) begin  // e30==-1
      if (!emb[0]) begin  // e0==-1
        tree_88 = 2'd3;
      end else begin  // e0==+1
        tree_88 = 2'd2;
      end
    end else begin  // e30==+1
      if (!emb[10]) begin  // e10==-1
        tree_88 = 2'd2;
      end else begin  // e10==+1
        tree_88 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 89: class 9, round 8
  function automatic [1:0] tree_89;
    input logic [63:0] emb;
  begin
  if (!emb[9]) begin  // e9==-1
    if (!emb[50]) begin  // e50==-1
      if (!emb[57]) begin  // e57==-1
        tree_89 = 2'd2;
      end else begin  // e57==+1
        tree_89 = 2'd2;
      end
    end else begin  // e50==+1
      if (!emb[36]) begin  // e36==-1
        tree_89 = 2'd1;
      end else begin  // e36==+1
        tree_89 = 2'd1;
      end
    end
  end else begin  // e9==+1
    if (!emb[22]) begin  // e22==-1
      if (!emb[30]) begin  // e30==-1
        tree_89 = 2'd1;
      end else begin  // e30==+1
        tree_89 = 2'd2;
      end
    end else begin  // e22==+1
      if (!emb[59]) begin  // e59==-1
        tree_89 = 2'd2;
      end else begin  // e59==+1
        tree_89 = 2'd3;
      end
    end
  end
  end
  endfunction
  // tree 90: class 0, round 9
  function automatic [1:0] tree_90;
    input logic [63:0] emb;
  begin
  if (!emb[3]) begin  // e3==-1
    if (!emb[15]) begin  // e15==-1
      if (!emb[58]) begin  // e58==-1
        tree_90 = 2'd1;
      end else begin  // e58==+1
        tree_90 = 2'd2;
      end
    end else begin  // e15==+1
      if (!emb[40]) begin  // e40==-1
        tree_90 = 2'd1;
      end else begin  // e40==+1
        tree_90 = 2'd0;
      end
    end
  end else begin  // e3==+1
    if (!emb[16]) begin  // e16==-1
      if (!emb[42]) begin  // e42==-1
        tree_90 = 2'd0;
      end else begin  // e42==+1
        tree_90 = 2'd2;
      end
    end else begin  // e16==+1
      if (!emb[37]) begin  // e37==-1
        tree_90 = 2'd3;
      end else begin  // e37==+1
        tree_90 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 91: class 1, round 9
  function automatic [1:0] tree_91;
    input logic [63:0] emb;
  begin
  if (!emb[21]) begin  // e21==-1
    if (!emb[63]) begin  // e63==-1
      if (!emb[45]) begin  // e45==-1
        tree_91 = 2'd0;
      end else begin  // e45==+1
        tree_91 = 2'd2;
      end
    end else begin  // e63==+1
      if (!emb[47]) begin  // e47==-1
        tree_91 = 2'd3;
      end else begin  // e47==+1
        tree_91 = 2'd2;
      end
    end
  end else begin  // e21==+1
    if (!emb[56]) begin  // e56==-1
      if (!emb[62]) begin  // e62==-1
        tree_91 = 2'd0;
      end else begin  // e62==+1
        tree_91 = 2'd0;
      end
    end else begin  // e56==+1
      if (!emb[53]) begin  // e53==-1
        tree_91 = 2'd3;
      end else begin  // e53==+1
        tree_91 = 2'd0;
      end
    end
  end
  end
  endfunction
  // tree 92: class 2, round 9
  function automatic [1:0] tree_92;
    input logic [63:0] emb;
  begin
  if (!emb[37]) begin  // e37==-1
    if (!emb[52]) begin  // e52==-1
      if (!emb[33]) begin  // e33==-1
        tree_92 = 2'd1;
      end else begin  // e33==+1
        tree_92 = 2'd3;
      end
    end else begin  // e52==+1
      if (!emb[30]) begin  // e30==-1
        tree_92 = 2'd2;
      end else begin  // e30==+1
        tree_92 = 2'd1;
      end
    end
  end else begin  // e37==+1
    if (!emb[23]) begin  // e23==-1
      if (!emb[35]) begin  // e35==-1
        tree_92 = 2'd2;
      end else begin  // e35==+1
        tree_92 = 2'd0;
      end
    end else begin  // e23==+1
      if (!emb[54]) begin  // e54==-1
        tree_92 = 2'd3;
      end else begin  // e54==+1
        tree_92 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 93: class 3, round 9
  function automatic [1:0] tree_93;
    input logic [63:0] emb;
  begin
  if (!emb[62]) begin  // e62==-1
    if (!emb[63]) begin  // e63==-1
      if (!emb[52]) begin  // e52==-1
        tree_93 = 2'd3;
      end else begin  // e52==+1
        tree_93 = 2'd1;
      end
    end else begin  // e63==+1
      if (!emb[8]) begin  // e8==-1
        tree_93 = 2'd0;
      end else begin  // e8==+1
        tree_93 = 2'd1;
      end
    end
  end else begin  // e62==+1
    if (!emb[24]) begin  // e24==-1
      if (!emb[31]) begin  // e31==-1
        tree_93 = 2'd2;
      end else begin  // e31==+1
        tree_93 = 2'd1;
      end
    end else begin  // e24==+1
      if (!emb[20]) begin  // e20==-1
        tree_93 = 2'd3;
      end else begin  // e20==+1
        tree_93 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 94: class 4, round 9
  function automatic [1:0] tree_94;
    input logic [63:0] emb;
  begin
  if (!emb[20]) begin  // e20==-1
    if (!emb[49]) begin  // e49==-1
      if (!emb[29]) begin  // e29==-1
        tree_94 = 2'd2;
      end else begin  // e29==+1
        tree_94 = 2'd1;
      end
    end else begin  // e49==+1
      if (!emb[29]) begin  // e29==-1
        tree_94 = 2'd1;
      end else begin  // e29==+1
        tree_94 = 2'd0;
      end
    end
  end else begin  // e20==+1
    if (!emb[24]) begin  // e24==-1
      if (!emb[8]) begin  // e8==-1
        tree_94 = 2'd3;
      end else begin  // e8==+1
        tree_94 = 2'd2;
      end
    end else begin  // e24==+1
      if (!emb[36]) begin  // e36==-1
        tree_94 = 2'd2;
      end else begin  // e36==+1
        tree_94 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 95: class 5, round 9
  function automatic [1:0] tree_95;
    input logic [63:0] emb;
  begin
  if (!emb[23]) begin  // e23==-1
    if (!emb[37]) begin  // e37==-1
      if (!emb[4]) begin  // e4==-1
        tree_95 = 2'd1;
      end else begin  // e4==+1
        tree_95 = 2'd3;
      end
    end else begin  // e37==+1
      if (!emb[25]) begin  // e25==-1
        tree_95 = 2'd3;
      end else begin  // e25==+1
        tree_95 = 2'd2;
      end
    end
  end else begin  // e23==+1
    if (!emb[62]) begin  // e62==-1
      if (!emb[5]) begin  // e5==-1
        tree_95 = 2'd3;
      end else begin  // e5==+1
        tree_95 = 2'd2;
      end
    end else begin  // e62==+1
      if (!emb[42]) begin  // e42==-1
        tree_95 = 2'd2;
      end else begin  // e42==+1
        tree_95 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 96: class 6, round 9
  function automatic [1:0] tree_96;
    input logic [63:0] emb;
  begin
  if (!emb[54]) begin  // e54==-1
    if (!emb[59]) begin  // e59==-1
      if (!emb[30]) begin  // e30==-1
        tree_96 = 2'd1;
      end else begin  // e30==+1
        tree_96 = 2'd3;
      end
    end else begin  // e59==+1
      if (!emb[47]) begin  // e47==-1
        tree_96 = 2'd2;
      end else begin  // e47==+1
        tree_96 = 2'd0;
      end
    end
  end else begin  // e54==+1
    if (!emb[25]) begin  // e25==-1
      if (!emb[45]) begin  // e45==-1
        tree_96 = 2'd1;
      end else begin  // e45==+1
        tree_96 = 2'd2;
      end
    end else begin  // e25==+1
      if (!emb[36]) begin  // e36==-1
        tree_96 = 2'd0;
      end else begin  // e36==+1
        tree_96 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 97: class 7, round 9
  function automatic [1:0] tree_97;
    input logic [63:0] emb;
  begin
  if (!emb[29]) begin  // e29==-1
    if (!emb[20]) begin  // e20==-1
      if (!emb[28]) begin  // e28==-1
        tree_97 = 2'd3;
      end else begin  // e28==+1
        tree_97 = 2'd2;
      end
    end else begin  // e20==+1
      if (!emb[57]) begin  // e57==-1
        tree_97 = 2'd2;
      end else begin  // e57==+1
        tree_97 = 2'd2;
      end
    end
  end else begin  // e29==+1
    if (!emb[31]) begin  // e31==-1
      if (!emb[28]) begin  // e28==-1
        tree_97 = 2'd2;
      end else begin  // e28==+1
        tree_97 = 2'd0;
      end
    end else begin  // e31==+1
      if (!emb[61]) begin  // e61==-1
        tree_97 = 2'd2;
      end else begin  // e61==+1
        tree_97 = 2'd1;
      end
    end
  end
  end
  endfunction
  // tree 98: class 8, round 9
  function automatic [1:0] tree_98;
    input logic [63:0] emb;
  begin
  if (!emb[18]) begin  // e18==-1
    if (!emb[23]) begin  // e23==-1
      if (!emb[55]) begin  // e55==-1
        tree_98 = 2'd1;
      end else begin  // e55==+1
        tree_98 = 2'd0;
      end
    end else begin  // e23==+1
      if (!emb[52]) begin  // e52==-1
        tree_98 = 2'd0;
      end else begin  // e52==+1
        tree_98 = 2'd2;
      end
    end
  end else begin  // e18==+1
    if (!emb[19]) begin  // e19==-1
      if (!emb[55]) begin  // e55==-1
        tree_98 = 2'd3;
      end else begin  // e55==+1
        tree_98 = 2'd2;
      end
    end else begin  // e19==+1
      if (!emb[63]) begin  // e63==-1
        tree_98 = 2'd2;
      end else begin  // e63==+1
        tree_98 = 2'd2;
      end
    end
  end
  end
  endfunction
  // tree 99: class 9, round 9
  function automatic [1:0] tree_99;
    input logic [63:0] emb;
  begin
  if (!emb[8]) begin  // e8==-1
    if (!emb[59]) begin  // e59==-1
      if (!emb[23]) begin  // e23==-1
        tree_99 = 2'd2;
      end else begin  // e23==+1
        tree_99 = 2'd1;
      end
    end else begin  // e59==+1
      if (!emb[2]) begin  // e2==-1
        tree_99 = 2'd3;
      end else begin  // e2==+1
        tree_99 = 2'd1;
      end
    end
  end else begin  // e8==+1
    if (!emb[32]) begin  // e32==-1
      if (!emb[37]) begin  // e37==-1
        tree_99 = 2'd0;
      end else begin  // e37==+1
        tree_99 = 2'd2;
      end
    end else begin  // e32==+1
      if (!emb[20]) begin  // e20==-1
        tree_99 = 2'd2;
      end else begin  // e20==+1
        tree_99 = 2'd2;
      end
    end
  end
  end
  endfunction

  // ── Per-class score accumulation (sum of 10 tree outputs, 0..30) ─
  logic [4:0] score_0;
  assign score_0 =
    5'(tree_0(embedding_i)) +
    5'(tree_10(embedding_i)) +
    5'(tree_20(embedding_i)) +
    5'(tree_30(embedding_i)) +
    5'(tree_40(embedding_i)) +
    5'(tree_50(embedding_i)) +
    5'(tree_60(embedding_i)) +
    5'(tree_70(embedding_i)) +
    5'(tree_80(embedding_i)) +
    5'(tree_90(embedding_i));
  logic [4:0] score_1;
  assign score_1 =
    5'(tree_1(embedding_i)) +
    5'(tree_11(embedding_i)) +
    5'(tree_21(embedding_i)) +
    5'(tree_31(embedding_i)) +
    5'(tree_41(embedding_i)) +
    5'(tree_51(embedding_i)) +
    5'(tree_61(embedding_i)) +
    5'(tree_71(embedding_i)) +
    5'(tree_81(embedding_i)) +
    5'(tree_91(embedding_i));
  logic [4:0] score_2;
  assign score_2 =
    5'(tree_2(embedding_i)) +
    5'(tree_12(embedding_i)) +
    5'(tree_22(embedding_i)) +
    5'(tree_32(embedding_i)) +
    5'(tree_42(embedding_i)) +
    5'(tree_52(embedding_i)) +
    5'(tree_62(embedding_i)) +
    5'(tree_72(embedding_i)) +
    5'(tree_82(embedding_i)) +
    5'(tree_92(embedding_i));
  logic [4:0] score_3;
  assign score_3 =
    5'(tree_3(embedding_i)) +
    5'(tree_13(embedding_i)) +
    5'(tree_23(embedding_i)) +
    5'(tree_33(embedding_i)) +
    5'(tree_43(embedding_i)) +
    5'(tree_53(embedding_i)) +
    5'(tree_63(embedding_i)) +
    5'(tree_73(embedding_i)) +
    5'(tree_83(embedding_i)) +
    5'(tree_93(embedding_i));
  logic [4:0] score_4;
  assign score_4 =
    5'(tree_4(embedding_i)) +
    5'(tree_14(embedding_i)) +
    5'(tree_24(embedding_i)) +
    5'(tree_34(embedding_i)) +
    5'(tree_44(embedding_i)) +
    5'(tree_54(embedding_i)) +
    5'(tree_64(embedding_i)) +
    5'(tree_74(embedding_i)) +
    5'(tree_84(embedding_i)) +
    5'(tree_94(embedding_i));
  logic [4:0] score_5;
  assign score_5 =
    5'(tree_5(embedding_i)) +
    5'(tree_15(embedding_i)) +
    5'(tree_25(embedding_i)) +
    5'(tree_35(embedding_i)) +
    5'(tree_45(embedding_i)) +
    5'(tree_55(embedding_i)) +
    5'(tree_65(embedding_i)) +
    5'(tree_75(embedding_i)) +
    5'(tree_85(embedding_i)) +
    5'(tree_95(embedding_i));
  logic [4:0] score_6;
  assign score_6 =
    5'(tree_6(embedding_i)) +
    5'(tree_16(embedding_i)) +
    5'(tree_26(embedding_i)) +
    5'(tree_36(embedding_i)) +
    5'(tree_46(embedding_i)) +
    5'(tree_56(embedding_i)) +
    5'(tree_66(embedding_i)) +
    5'(tree_76(embedding_i)) +
    5'(tree_86(embedding_i)) +
    5'(tree_96(embedding_i));
  logic [4:0] score_7;
  assign score_7 =
    5'(tree_7(embedding_i)) +
    5'(tree_17(embedding_i)) +
    5'(tree_27(embedding_i)) +
    5'(tree_37(embedding_i)) +
    5'(tree_47(embedding_i)) +
    5'(tree_57(embedding_i)) +
    5'(tree_67(embedding_i)) +
    5'(tree_77(embedding_i)) +
    5'(tree_87(embedding_i)) +
    5'(tree_97(embedding_i));
  logic [4:0] score_8;
  assign score_8 =
    5'(tree_8(embedding_i)) +
    5'(tree_18(embedding_i)) +
    5'(tree_28(embedding_i)) +
    5'(tree_38(embedding_i)) +
    5'(tree_48(embedding_i)) +
    5'(tree_58(embedding_i)) +
    5'(tree_68(embedding_i)) +
    5'(tree_78(embedding_i)) +
    5'(tree_88(embedding_i)) +
    5'(tree_98(embedding_i));
  logic [4:0] score_9;
  assign score_9 =
    5'(tree_9(embedding_i)) +
    5'(tree_19(embedding_i)) +
    5'(tree_29(embedding_i)) +
    5'(tree_39(embedding_i)) +
    5'(tree_49(embedding_i)) +
    5'(tree_59(embedding_i)) +
    5'(tree_69(embedding_i)) +
    5'(tree_79(embedding_i)) +
    5'(tree_89(embedding_i)) +
    5'(tree_99(embedding_i));

  // ── Argmax: linear scan, ties broken by lower class index ───────────────
  logic [4:0] max_score;
  always_comb begin
    number_o  = 4'd0;
    max_score = score_0;
    if (score_1 > max_score) begin
      max_score = score_1;
      number_o  = 4'd1;
    end
    if (score_2 > max_score) begin
      max_score = score_2;
      number_o  = 4'd2;
    end
    if (score_3 > max_score) begin
      max_score = score_3;
      number_o  = 4'd3;
    end
    if (score_4 > max_score) begin
      max_score = score_4;
      number_o  = 4'd4;
    end
    if (score_5 > max_score) begin
      max_score = score_5;
      number_o  = 4'd5;
    end
    if (score_6 > max_score) begin
      max_score = score_6;
      number_o  = 4'd6;
    end
    if (score_7 > max_score) begin
      max_score = score_7;
      number_o  = 4'd7;
    end
    if (score_8 > max_score) begin
      max_score = score_8;
      number_o  = 4'd8;
    end
    if (score_9 > max_score) begin
      max_score = score_9;
      number_o  = 4'd9;
    end
  end

endmodule