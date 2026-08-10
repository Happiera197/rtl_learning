`timescale 1ns/1ps

module tb_sync_fifo;

    localparam int unsigned DATA_WIDTH    = 8;
    localparam int unsigned DATA_DEPTH    = 4;
    localparam int unsigned COUNT_WIDTH   = $clog2(DATA_DEPTH + 1);
    localparam int unsigned RANDOM_CYCLES = 10000;

    logic                   clk;
    logic                   resetn;
    logic                   wren;
    logic [DATA_WIDTH-1:0]  wdata;
    logic                   rden;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   empty;
    logic                   full;
    logic [COUNT_WIDTH-1:0] count;

    logic [DATA_WIDTH-1:0] ref_q[$];

    fifo_transaction tr;


    int unsigned error_count;
    int unsigned check_count;

    string test_name;

    bit hit_full;
    bit hit_empty;
    bit hit_rw;
    bit hit_wrap;

    int unsigned accepted_write_count;
    int unsigned accepted_read_count;

    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DATA_DEPTH (DATA_DEPTH)
    ) dut (
        .clk    (clk),
        .resetn (resetn),
        .wren   (wren),
        .wdata  (wdata),
        .rden   (rden),
        .rdata  (rdata),
        .empty  (empty),
        .full   (full),
        .count  (count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

task automatic report_error(
        input string message
    );
        begin

            $display(
                "[%0t] ERROR: %s",
                $time,
                message
            );

            error_count++;

        end
    endtask

task automatic check_status;

        logic expected_empty;
        logic expected_full;
        logic [COUNT_WIDTH-1:0] expected_count;

        begin

            expected_empty =
                (ref_q.size() == 0);

            expected_full =
                (ref_q.size() == DATA_DEPTH);

            expected_count =
                COUNT_WIDTH'(ref_q.size());


            check_count += 3;


            if (count !== expected_count) begin

                report_error(
                    $sformatf(
                        "count mismatch: expected=%0d actual=%0d",
                        ref_q.size(),
                        count
                    )
                );

            end


            if (empty !== expected_empty) begin

                report_error(
                    $sformatf(
                        "empty mismatch: expected=%0b actual=%0b",
                        expected_empty,
                        empty
                    )
                );

            end


            if (full !== expected_full) begin

                report_error(
                    $sformatf(
                        "full mismatch: expected=%0b actual=%0b",
                        expected_full,
                        full
                    )
                );

            end

        end
    endtask

task automatic reset_random_tracking;

        begin

            hit_full  = 1'b0;
            hit_empty = 1'b0;
            hit_rw    = 1'b0;
            hit_wrap  = 1'b0;

            accepted_write_count = 0;
            accepted_read_count  = 0;

        end
    endtask

task automatic check_random_hits;

        begin

            check_count += 4;


            if (!hit_full)
                report_error(
                    "random generator did not hit FULL"
                );


            if (!hit_empty)
                report_error(
                    "random generator did not hit EMPTY"
                );


            if (!hit_rw)
                report_error(
                    "random generator did not hit simultaneous R/W"
                );


            if (!hit_wrap)
                report_error(
                    "random generator did not hit pointer wraparound"
                );


            $display("");
            $display("----------------------------------------");
            $display("Random Generator Coverage");
            $display("----------------------------------------");
            $display(
                "Full hit        : %s",
                hit_full ? "YES" : "NO"
            );
            $display(
                "Empty hit       : %s",
                hit_empty ? "YES" : "NO"
            );
            $display(
                "Simultaneous RW : %s",
                hit_rw ? "YES" : "NO"
            );
            $display(
                "Wraparound hit  : %s",
                hit_wrap ? "YES" : "NO"
            );
            $display("----------------------------------------");

        end
    endtask

 task automatic apply_reset;

        begin

            @(negedge clk);

            wren  = 1'b0;
            rden  = 1'b0;
            wdata = '0;


            /*
             * 在两个时钟沿之间拉低 resetn，
             * 验证异步复位。
             */
            #2;

            resetn = 1'b0;

            ref_q.delete();


            #1;


            check_count += 4;


            if (count !== '0)
                report_error(
                    "count was not cleared by asynchronous reset"
                );


            if (empty !== 1'b1)
                report_error(
                    "empty was not asserted by asynchronous reset"
                );


            if (full !== 1'b0)
                report_error(
                    "full was asserted after asynchronous reset"
                );


            if (rdata !== '0)
                report_error(
                    "rdata was not cleared by asynchronous reset"
                );


            repeat (2)
                @(posedge clk);


            @(negedge clk);

            resetn = 1'b1;


            #1;

            check_status();

        end
    endtask

task automatic fifo_step(
        input logic                  request_write,
        input logic                  request_read,
        input logic [DATA_WIDTH-1:0] input_data
    );

        logic expected_wr_fire;
        logic expected_rd_fire;

        logic [DATA_WIDTH-1:0] expected_read_data;

        int unsigned old_size;


        begin

            old_size = ref_q.size();

            expected_rd_fire =
                request_read &&
                (old_size > 0);

            expected_wr_fire =
                request_write &&
                (
                    (old_size < DATA_DEPTH) ||
                    expected_rd_fire
                );

            if (expected_rd_fire)
                expected_read_data = ref_q[0];

            else
                expected_read_data = '0;

            @(negedge clk);

            wren  = request_write;
            rden  = request_read;
            wdata = input_data;


            @(posedge clk);

            #1;

            if (expected_rd_fire) begin
                check_count++;
                if (rdata !== expected_read_data) begin

                    report_error(
                        $sformatf(
                            "read mismatch: expected=0x%0h actual=0x%0h",
                            expected_read_data,
                            rdata
                        )
                    );

                end

            end

            if (expected_rd_fire)
                 void'(ref_q.pop_front());


            if (expected_wr_fire)
                ref_q.push_back(input_data);


            if (expected_wr_fire)
                accepted_write_count++;

            if (expected_rd_fire)
                accepted_read_count++;



            if (ref_q.size() == DATA_DEPTH)
                hit_full = 1'b1;


            if (ref_q.size() == 0)
                hit_empty = 1'b1;

            if (
                expected_wr_fire &&
                expected_rd_fire
            )
                hit_rw = 1'b1;

            if (
                (accepted_write_count >= DATA_DEPTH) &&
                (accepted_read_count  >= DATA_DEPTH)
            )
                hit_wrap = 1'b1;


            check_status();

            @(negedge clk);

            wren  = 1'b0;
            rden  = 1'b0;
            wdata = '0;

        end
    endtask

task automatic drain_fifo;
            while (ref_q.size() > 0) begin

                fifo_step(
                    1'b0,
                    1'b1,
                    '0
                );

            end
endtask

 task automatic run_basic;

        begin

            $display("[TEST basic] reset");

            apply_reset();


            $display(
                "[TEST basic] normal write/read"
            );

            fifo_step(
                1'b1,
                1'b0,
                8'h11
            );

            fifo_step(
                1'b1,
                1'b0,
                8'h22
            );

            fifo_step(
                1'b1,
                1'b0,
                8'h33
            );


            fifo_step(
                1'b0,
                1'b1,
                '0
            );

            fifo_step(
                1'b0,
                1'b1,
                '0
            );

            $display(
                "[TEST basic] pointer wrap-around"
            );


            fifo_step(
                1'b1,
                1'b0,
                8'h44
            );

            fifo_step(
                1'b1,
                1'b0,
                8'h55
            );

            fifo_step(
                1'b1,
                1'b0,
                8'h66
            );


            drain_fifo();

        end
    endtask

    task automatic run_reset;

        begin

            $display(
                "[TEST reset] initial asynchronous reset"
            );

            apply_reset();


            $display(
                "[TEST reset] write before mid-stream reset"
            );

            fifo_step(
                1'b1,
                1'b0,
                8'hC1
            );

            fifo_step(
                1'b1,
                1'b0,
                8'hC2
            );


            $display(
                "[TEST reset] mid-stream reset"
            );

            apply_reset();


            $display(
                "[TEST reset] operation after reset"
            );

            fifo_step(
                1'b1,
                1'b0,
                8'hD1
            );

            fifo_step(
                1'b0,
                1'b1,
                '0
            );

        end
    endtask


    task automatic run_full_empty;

        int unsigned i;

        begin

            apply_reset();


            $display(
                "[TEST full_empty] empty-read protection"
            );

            fifo_step(
                1'b0,
                1'b1,
                '0
            );


            $display(
                "[TEST full_empty] fill FIFO to full"
            );


            for (
                i = 0;
                i < DATA_DEPTH;
                i++
            ) begin

                fifo_step(
                    1'b1,
                    1'b0,
                    DATA_WIDTH'(8'h20 + i)
                );

            end


            $display(
                "[TEST full_empty] full-write protection"
            );

            fifo_step(
                1'b1,
                1'b0,
                8'hEE
            );


            $display(
                "[TEST full_empty] drain FIFO to empty"
            );

            drain_fifo();


            $display(
                "[TEST full_empty] empty-read protection again"
            );

            fifo_step(
                1'b0,
                1'b1,
                '0
            );

        end
    endtask



    task automatic run_simultaneous_rw;

        int unsigned i;

        begin

            apply_reset();


            $display(
                "[TEST simultaneous_rw] simultaneous R/W while empty"
            );


            fifo_step(
                1'b1,
                1'b1,
                8'h66
            );


            fifo_step(
                1'b0,
                1'b1,
                '0
            );


            $display(
                "[TEST simultaneous_rw] fill FIFO to full"
            );


            for (
                i = 0;
                i < DATA_DEPTH;
                i++
            ) begin

                fifo_step(
                    1'b1,
                    1'b0,
                    DATA_WIDTH'(8'h30 + i)
                );

            end


            $display(
                "[TEST simultaneous_rw] simultaneous R/W while full"
            );


            fifo_step(
                1'b1,
                1'b1,
                8'h77
            );


            fifo_step(
                1'b0,
                1'b1,
                '0
            );

            fifo_step(
                1'b0,
                1'b1,
                '0
            );


            $display(
                "[TEST simultaneous_rw] simultaneous R/W in normal state"
            );


            fifo_step(
                1'b1,
                1'b1,
                8'h88
            );


            drain_fifo();

        end
    endtask

task automatic run_random;
int unsigned i;
begin
apply_reset();

            reset_random_tracking();
            $display("");
            $display(
                "[TEST random] directed random preparation");

    $display(
                "[TEST random] actively hit FULL"
            );


            while (ref_q.size() < DATA_DEPTH) begin

                tr.force_write();

                fifo_step(
                    tr.write,
                    tr.read,
                    tr.data
                );

            end

            $display(
                "[TEST random] actively hit EMPTY"
            );


            while (ref_q.size() > 0) begin

                tr.force_read();

                fifo_step(
                    tr.write,
                    tr.read,
                    tr.data
                );

            end

            $display(
                "[TEST random] move FIFO to middle level"
            );


            for (
                i = 0;
                i < DATA_DEPTH / 2;
                i++
            ) begin

                tr.force_write();

                fifo_step(
                    tr.write,
                    tr.read,
                    tr.data
                );

            end
 $display(
                "[TEST random] simultaneous R/W and wraparound"
            );


            repeat (DATA_DEPTH * 2) begin

                tr.force_rw();

                fifo_step(
                    tr.write,
                    tr.read,
                    tr.data
                );

            end
            $display(
                "[TEST random] %0d-cycle state-aware randomized regression",
                RANDOM_CYCLES
            );


            repeat (RANDOM_CYCLES) begin
                tr.randomize_fallback(
                    ref_q.size(),
                    DATA_DEPTH
                );


                fifo_step(
                    tr.write,
                    tr.read,
                    tr.data
                );

            end

            drain_fifo();

            check_random_hits();

end
endtask
initial begin

        resetn = 1'b1;
        wren   = 1'b0;
        rden   = 1'b0;
        wdata  = '0;


        error_count = 0;
        check_count = 0;


        ref_q.delete();



        tr = new();
        reset_random_tracking();

        if ($test$plusargs("TRACE")) begin

            $dumpfile(
                "sync_fifo.fst"
            );

            $dumpvars(
                0,
                tb_sync_fifo
            );

        end

        if (
            !$value$plusargs(
                "TEST=%s",
                test_name
            )
        )
            test_name = "basic";


        $display("");
        $display("========================================");
        $display(
            "Running FIFO test: %s",
            test_name
        );
        $display("========================================");


        case (test_name)

            "basic":
                run_basic();


            "reset":
                run_reset();


            "full_empty":
                run_full_empty();


            "simultaneous_rw":
                run_simultaneous_rw();


            "random":
                run_random();


            default:
                $fatal(
                    1,
                    "Unknown TEST=%s. Valid tests: basic reset full_empty simultaneous_rw random",
                    test_name
                );

        endcase


        $display("");
        $display("========================================");
        $display("FIFO Verification Summary");
        $display(
            "Test   : %s",
            test_name
        );
        $display(
            "Checks : %0d",
            check_count
        );
        $display(
            "Errors : %0d",
            error_count
        );


        if (error_count == 0) begin

            $display(
                "RESULT : PASS"
            );

            $display(
                "========================================"
            );

        end

        else begin

            $display(
                "RESULT : FAIL"
            );

            $display(
                "========================================"
            );


            $fatal(
                1,
                "Test %s failed with %0d errors",
                test_name,
                error_count
            );

        end


        #10;

        $finish;

    end


endmodule
