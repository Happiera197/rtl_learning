`timescale 1ns/1ps
`include "fifo_if.sv"
`include "fifo_transaction.sv"
`include "fifo_generator.sv"
`include "fifo_driver.sv"
`include "fifo_monitor.sv"
`include "fifo_scoreboard.sv"
`include "fifo_coverage.sv"

module tb_sync_fifo;

    localparam int unsigned DATA_WIDTH    = 8;
    localparam int unsigned DATA_DEPTH    = 16;

    logic clk;

    logic [DATA_WIDTH-1:0] ref_q[$];

    fifo_transaction tr;
 initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
fifo_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH)
    ) vif (
        .clk(clk)
    );
    /*
    int unsigned error_count;
    int unsigned check_count;

    string test_name;

    bit hit_full;
    bit hit_empty;
    bit hit_rw;
    bit hit_wrap;

    int unsigned accepted_write_count;
    int unsigned accepted_read_count;
*/
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH)
    ) dut (
        .clk    (clk),
        .resetn (vif.resetn),

        .wren   (vif.wren),
        .wdata  (vif.wdata),

        .rden   (vif.rden),
        .rdata  (vif.rdata),

        .empty  (vif.empty),
        .full   (vif.full),
        .count  (vif.count)
    );

mailbox #(fifo_transaction) gen2drv;
mailbox #(fifo_transaction) mon2scb;

    event drv_done;

    fifo_generator  gen;
    fifo_driver     drv;
    fifo_monitor    mon;
    fifo_scoreboard scb;
    fifo_coverage   cov;

initial begin
    gen2drv = new();
    mon2scb = new();

        gen = new(
            gen2drv,
            drv_done
        );
        drv = new(
            vif,
            gen2drv,
            drv_done
        );
        mon = new(
            vif,
            mon2scb
        );
        scb = new(
            mon2scb
        );
        cov = new(
            vif,
            DATA_DEPTH
        );

        vif.resetn = 1'b0;
        vif.wren   = 1'b0;
        vif.rden   = 1'b0;
        vif.wdata  = '0;

        repeat (3)
            @(posedge clk);
        vif.resetn = 1'b1;
        @(posedge clk);
    fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_any
    repeat (2)
            @(posedge clk);
        disable fork;
        $display("");
        $display("========================================");
        $display("FIFO Verification Finished");
        $display("========================================");
        $finish;

end

endmodule
