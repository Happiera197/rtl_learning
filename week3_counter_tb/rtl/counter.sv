`timescale 1ns/1ps
module counter #(
    parameter int unsigned WIDTH = 4
)(
    input logic clk,
    input logic resetn,
    input logic en,
    output logic [WIDTH-1:0]count
);
    always_ff @(posedge clk,negedge resetn) begin
        if(!resetn)count<='0;
        else if(en)count<=count+1'b1;
        else count<=count;
    end

endmodule
