`timescale 1ns/1ps
module sync_fifo#(
    parameter int unsigned DATA_WIDTH=8,
    parameter int unsigned DATA_DEPTH=16
)(
input logic clk,
input logic resetn,

input logic wren,
input logic [DATA_WIDTH-1:0]wdata,
input logic rden,
output logic [DATA_WIDTH-1:0]rdata,

output logic empty,
output logic full,
output logic [$clog2(DATA_DEPTH+1)-1:0]count
);
localparam int unsigned COUNT_WIDTH = $clog2(DATA_DEPTH+1);
localparam int unsigned PTR_WIDTH = (DATA_DEPTH <= 1) ? 1 : $clog2(DATA_DEPTH);
localparam logic [PTR_WIDTH-1:0]LAST_ADDR = PTR_WIDTH'(DATA_DEPTH-1);
localparam logic [COUNT_WIDTH-1:0]DEPTH_COUNT = COUNT_WIDTH'(DATA_DEPTH);

logic [PTR_WIDTH-1:0] rdptr,wrptr;

logic [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

logic wrfire,rdfire;

assign wrfire=wren&&(!full||rdfire);
//FIFO 已满，但本周期同时成功读取，读操作腾出了一个位置，因此仍可写入。
assign rdfire=rden&&(!empty);

assign full=(count==DEPTH_COUNT);
assign empty=(count=='0);

always_ff @(posedge clk,negedge resetn) begin
    if(!resetn)begin
        wrptr<='0;
        rdptr<='0;
        count<='0;
        rdata<='0;
    end
    else begin
        if(wrfire)begin
            mem[wrptr]<=wdata;
            if(wrptr==LAST_ADDR)wrptr<='0;
            else wrptr<=wrptr+1'b1;
        end

        if(rdfire)begin
            rdata<=mem[rdptr];
            if(rdptr==LAST_ADDR)rdptr<='0;
            else rdptr<=rdptr+1'b1;
        end

        case({wrfire,rdfire})
        2'b10:count<=count+1'b1;
        2'b01:count<=count-1'b1;
        default:count<=count;
        endcase
    end
end

`ifndef SYNTHESIS
 initial begin
     if(DATA_DEPTH<1) $fatal(1,"DATA_DEPTH must be at least 1");
     if(DATA_WIDTH<1)$fatal(1, "DATA_WIDTH must be at least 1");
 end

 always_ff@(posedge clk)begin
    if(resetn)begin
            assert (count<=DEPTH_COUNT)
            else   $fatal(1, "FIFO count overflow");

            assert(!(full&&empty))
             else $fatal(1, "FIFO cannot be full and empty simultaneously");
    end
 end
`endif
endmodule
