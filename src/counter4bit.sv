

module counter4bit (
  input logic rst_n,
  input logic clk,
  output logic [3:0] data_out
);

  logic [3:0] data;
  logic [3:0] data_next;

  assign data_out = data;
  assign data_next = data+1;
  
  always_ff @(posedge clk or negedge rst_n) begin : increment
    if(!rst_n)
      data <= 0;
    else
      data <= data_next;
  end

endmodule