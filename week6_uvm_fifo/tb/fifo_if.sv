interface fifo_if #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DATA_DEPTH = 16
)(
    input logic clk
);
    logic resetn;

    logic wren;
    logic rden;

    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    logic full;
    logic empty;
    logic [$clog2(DATA_DEPTH+1)-1:0] count;

endinterface
