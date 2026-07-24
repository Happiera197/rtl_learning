`timescale 1ns/1ps
module ram16x8_async_read(
    input logic clk,
    input logic we,
    input logic [3:0]addr,
    input logic [7:0]wdata,
    output logic [7:0]rdata
);

logic [7:0]mem[0:15];
always_ff @(posedge clk) begin
    if(we) mem[addr]<=wdata;
end

assign rdata=mem[addr];

endmodule
