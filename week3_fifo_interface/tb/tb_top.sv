`timescale 1ns/1ps
module tb_top;
    localparam int unsigned DATA_WIDTH=8;
    localparam int unsigned DATA_DEPTH=16;
    logic clk;

    initial begin
        clk=1'b0;
    end

    always #5 clk=~clk;

    fifo_if #(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_DEPTH (DATA_DEPTH)
    ) fifo_bus (
        .clk (clk)
    );

    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_DEPTH (DATA_DEPTH)
    ) dut (
        .clk(fifo_bus.clk),
        .resetn(fifo_bus.resetn),

        .wren   (fifo_bus.wren),
        .wdata  (fifo_bus.wdata),

        .rden   (fifo_bus.rden),
        .rdata  (fifo_bus.rdata),

        .empty  (fifo_bus.empty),
        .full   (fifo_bus.full),
        .count  (fifo_bus.count)

    );

    fifo_test #(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_DEPTH (DATA_DEPTH)
    ) test_program(
        .fifo(fifo_bus)
    );

    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, tb_top);
    end
endmodule
