`timescale 1ns/1ps

module tb_sync_fifo;

    localparam int unsigned DATA_WIDTH  = 8;
    localparam int unsigned DATA_DEPTH  = 4;
    localparam int unsigned COUNT_WIDTH = $clog2(DATA_DEPTH + 1);

    logic clk;
    logic resetn;

    logic                  wren;
    logic [DATA_WIDTH-1:0] wdata;

    logic                  rden;
    logic [DATA_WIDTH-1:0] rdata;

    logic empty;
    logic full;
    logic [COUNT_WIDTH-1:0] count;

    /*
     * 参考模型。
     *
     * 不使用 SystemVerilog 动态队列，
     * 而是自己建立一套软件 FIFO。
     */
    logic [DATA_WIDTH-1:0] model_mem [0:DATA_DEPTH-1];

    int unsigned model_wrptr;
    int unsigned model_rdptr;
    int unsigned model_count;

    int unsigned error_count;

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

    /*
     * 10 ns 时钟周期。
     */
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    /*
     * 报告错误。
     *
     * 不直接使用 $error，避免 Verilator
     * 在第一次错误时就停止仿真。
     */
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

    /*
     * 模型指针加一，并在最后一个地址处回绕。
     */
    function automatic int unsigned next_model_ptr(
        input int unsigned ptr
    );
        begin
            if (ptr == DATA_DEPTH - 1)
                next_model_ptr = 0;
            else
                next_model_ptr = ptr + 1;
        end
    endfunction

    /*
     * 检查 count、empty、full。
     */
    task automatic check_status;
        logic expected_empty;
        logic expected_full;
        logic [COUNT_WIDTH-1:0] expected_count;
        begin
            expected_empty = (model_count == 0);
            expected_full  = (model_count == DATA_DEPTH);
            expected_count = COUNT_WIDTH'(model_count);

            if (count !== expected_count) begin
                report_error(
                    $sformatf(
                        "count mismatch: expected=%0d actual=%0d",
                        model_count,
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

    /*
     * 对 DUT 和参考模型执行异步复位。
     */
    task automatic apply_reset;
        begin
            @(negedge clk);

            wren  = 1'b0;
            rden  = 1'b0;
            wdata = '0;

            /*
             * 在两个时钟沿之间拉低复位，
             * 验证异步复位。
             */
            #2;
            resetn = 1'b0;

            model_wrptr = 0;
            model_rdptr = 0;
            model_count = 0;

            #1;

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

            repeat (2) @(posedge clk);

            @(negedge clk);
            resetn = 1'b1;

            #1;
            check_status();
        end
    endtask

    /*
     * 执行一个读写周期。
     */
    task automatic fifo_step(
        input logic                  request_write,
        input logic                  request_read,
        input logic [DATA_WIDTH-1:0] input_data
    );
        logic expected_wr_fire;
        logic expected_rd_fire;
        logic [DATA_WIDTH-1:0] expected_read_data;

        int unsigned old_wrptr;
        int unsigned old_rdptr;
        int unsigned old_count;
        begin
            /*
             * 保存时钟沿前的模型状态。
             */
            old_wrptr = model_wrptr;
            old_rdptr = model_rdptr;
            old_count = model_count;

            /*
             * FIFO 非空才能真正读取。
             */
            expected_rd_fire =
                request_read && (old_count > 0);

            /*
             * FIFO 未满时可以写。
             *
             * FIFO 已满但本周期会读出一个数据时，
             * 也允许写入。
             */
            expected_wr_fire =
                request_write &&
                (
                    (old_count < DATA_DEPTH) ||
                    expected_rd_fire
                );

            /*
             * 在修改参考模型前保存预期读数据。
             */
            if (expected_rd_fire)
                expected_read_data = model_mem[old_rdptr];
            else
                expected_read_data = '0;

            /*
             * 在下降沿改变输入，保证其在下一上升沿前稳定。
             */
            @(negedge clk);

            wren  = request_write;
            rden  = request_read;
            wdata = input_data;

            /*
             * DUT 在上升沿执行操作。
             */
            @(posedge clk);
            #1;

            /*
             * 检查同步读输出。
             */
            if (
                expected_rd_fire &&
                (rdata !== expected_read_data)
            ) begin
                report_error(
                    $sformatf(
                        "read mismatch: expected=0x%0h actual=0x%0h",
                        expected_read_data,
                        rdata
                    )
                );
            end

            /*
             * 更新参考模型存储器。
             *
             * 满状态同时读写时，old_wrptr 和 old_rdptr
             * 可能相同。预期读数据已经提前保存，因此
             * 此处可以安全写入新数据。
             */
            if (expected_wr_fire)
                model_mem[old_wrptr] = input_data;

            /*
             * 更新参考模型指针。
             */
            if (expected_rd_fire)
                model_rdptr = next_model_ptr(old_rdptr);

            if (expected_wr_fire)
                model_wrptr = next_model_ptr(old_wrptr);

            /*
             * 更新参考模型数据数量。
             */
            case ({
                expected_wr_fire,
                expected_rd_fire
            })
                2'b10:
                    model_count = old_count + 1;

                2'b01:
                    model_count = old_count - 1;

                default:
                    model_count = old_count;
            endcase

            check_status();

            /*
             * 操作完成后撤销请求。
             */
            @(negedge clk);

            wren  = 1'b0;
            rden  = 1'b0;
            wdata = '0;
        end
    endtask

    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);

        resetn = 1'b1;

        wren  = 1'b0;
        wdata = '0;
        rden  = 1'b0;

        model_wrptr = 0;
        model_rdptr = 0;
        model_count = 0;

        error_count = 0;

        $display("[FIFO] asynchronous reset");
        apply_reset();

        /*
         * FIFO 为空时读取。
         */
        $display("[FIFO] empty-read protection");
        fifo_step(
            1'b0,
            1'b1,
            8'h00
        );

        /*
         * 依次写入四个数据，使 FIFO 变满。
         */
        $display("[FIFO] fill to full");

        fifo_step(1'b1, 1'b0, 8'h11);
        fifo_step(1'b1, 1'b0, 8'h22);
        fifo_step(1'b1, 1'b0, 8'h33);
        fifo_step(1'b1, 1'b0, 8'h44);

        /*
         * 满状态只写，0xEE 应被拒绝。
         */
        $display("[FIFO] full-write protection");

        fifo_step(
            1'b1,
            1'b0,
            8'hEE
        );

        /*
         * 满状态同时读写。
         *
         * 应读出 0x11，并将 0x55 放到队尾。
         * 操作后 FIFO 仍然有四个数据。
         */
        $display(
            "[FIFO] simultaneous read/write while full"
        );

        fifo_step(
            1'b1,
            1'b1,
            8'h55
        );

        /*
         * 此时数据顺序应为：
         *
         * 22、33、44、55
         */
        $display("[FIFO] drain and check order");

        fifo_step(1'b0, 1'b1, '0);
        fifo_step(1'b0, 1'b1, '0);
        fifo_step(1'b0, 1'b1, '0);
        fifo_step(1'b0, 1'b1, '0);

        /*
         * 空状态同时读写。
         *
         * 由于空状态不能读取，本周期只会写入 0x66。
         */
        $display(
            "[FIFO] simultaneous read/write while empty"
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

        /*
         * 指针回绕测试。
         */
        $display("[FIFO] pointer wrap-around");

        fifo_step(1'b1, 1'b0, 8'hA1);
        fifo_step(1'b1, 1'b0, 8'hA2);
        fifo_step(1'b1, 1'b0, 8'hA3);

        fifo_step(1'b0, 1'b1, '0);
        fifo_step(1'b0, 1'b1, '0);

        fifo_step(1'b1, 1'b0, 8'hB1);
        fifo_step(1'b1, 1'b0, 8'hB2);
        fifo_step(1'b1, 1'b0, 8'hB3);

        while (model_count > 0) begin
            fifo_step(
                1'b0,
                1'b1,
                '0
            );
        end

        /*
         * 随机读写测试。
         */
        $display("[FIFO] randomized regression");

        repeat (300) begin
            fifo_step(
                ($urandom_range(0, 1) != 0),
                ($urandom_range(0, 1) != 0),
                DATA_WIDTH'($urandom)
            );
        end

        /*
         * 清空随机测试后剩余的数据。
         */
        while (model_count > 0) begin
            fifo_step(
                1'b0,
                1'b1,
                '0
            );
        end

        /*
         * 中途复位测试。
         */
        $display("[FIFO] mid-stream reset");

        fifo_step(1'b1, 1'b0, 8'hC1);
        fifo_step(1'b1, 1'b0, 8'hC2);

        apply_reset();

        fifo_step(1'b1, 1'b0, 8'hD1);
        fifo_step(1'b0, 1'b1, '0);

        if (error_count == 0) begin
            $display("========================================");
            $display("PASS: tb_sync_fifo");
            $display("========================================");
        end
        else begin
            $fatal(
                1,
                "FAIL: tb_sync_fifo, errors=%0d",
                error_count
            );
        end

        #10;
        $finish;
    end

endmodule
