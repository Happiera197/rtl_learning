`timescale 1ns/1ps
interface fifo_if #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DATA_DEPTH = 16
)(
    input logic clk
);
localparam int unsigned COUNT_WIDTH=$clog2(DATA_DEPTH+1);

logic resetn;

logic wren;
logic [DATA_WIDTH-1:0]wdata;
logic rden;
logic [DATA_WIDTH-1:0]rdata;

logic empty;
logic full;
logic [DATA_WIDTH-1:0]count;

clocking tb_cb@(posedge clk);
    default input #1step output #0;

    output wren;
    output wdata;
    output rden;

    input rdata;
    input empty;
    input full;
    input count;
endclocking
endinterface
