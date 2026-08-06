`timescale 1ns/1ps

module tb_rv_buffer_1entry;

    localparam int unsigned DATA_WIDTH = 8;

    logic clk;
    logic resetn;

    /*
     * 上游接口。
     */
    logic                  i_valid;
    logic                  o_ready;
    logic [DATA_WIDTH-1:0] i_data;

    /*
     * 下游接口。
     */
    logic                  o_valid;
    logic                  i_ready;
    logic [DATA_WIDTH-1:0] o_data;

    /*
     * 参考模型。
     *
     * 1-entry buffer 只有两种状态：
     *
     * model_valid = 0：空
     * model_valid = 1：保存了一个有效数据
     */
    logic                  model_valid;
    logic [DATA_WIDTH-1:0] model_data;

    int unsigned error_count;

    rv_buffer_1entry #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk     (clk),
        .resetn  (resetn),

        .i_valid (i_valid),
        .o_ready (o_ready),
        .i_data  (i_data),

        .o_valid (o_valid),
        .i_ready (i_ready),
        .o_data  (o_data)
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
     * 检查缓冲器当前状态。
     */
    task automatic check_state;
        begin
            if (o_valid !== model_valid) begin
                report_error(
                    $sformatf(
                        "o_valid mismatch: expected=%0b actual=%0b",
                        model_valid,
                        o_valid
                    )
                );
            end

            /*
             * 只有 model_valid=1 时，o_data 才需要检查。
             */
            if (
                model_valid &&
                (o_data !== model_data)
            ) begin
                report_error(
                    $sformatf(
                        "o_data mismatch: expected=0x%0h actual=0x%0h",
                        model_data,
                        o_data
                    )
                );
            end
        end
    endtask

    /*
     * 异步复位。
     */
    task automatic apply_reset;
        begin
            @(negedge clk);

            i_valid = 1'b0;
            i_ready = 1'b0;
            i_data  = '0;

            #2;
            resetn = 1'b0;

            model_valid = 1'b0;
            model_data  = '0;

            #1;

            if (o_valid !== 1'b0)
                report_error(
                    "o_valid was not cleared by asynchronous reset"
                );

            if (o_data !== '0)
                report_error(
                    "o_data was not cleared by asynchronous reset"
                );

            if (o_ready !== 1'b1)
                report_error(
                    "empty buffer did not assert o_ready after reset"
                );

            repeat (2) @(posedge clk);

            @(negedge clk);
            resetn = 1'b1;

            #1;
            check_state();
        end
    endtask

    /*
     * 执行一个 ready-valid 周期。
     */
    task automatic buffer_step(
        input logic                  upstream_valid,
        input logic [DATA_WIDTH-1:0] upstream_data,
        input logic                  downstream_ready
    );
        logic expected_ready;
        logic expected_input_fire;
        logic expected_output_fire;

        logic old_valid;
        logic [DATA_WIDTH-1:0] old_data;
        begin
            /*
             * 保存时钟沿前的缓冲器状态。
             */
            old_valid = model_valid;
            old_data  = model_data;

            /*
             * 缓冲器为空，或者下游会取走旧数据时，
             * 可以接收上游数据。
             */
            expected_ready =
                !old_valid || downstream_ready;

            /*
             * 输入端握手。
             */
            expected_input_fire =
                upstream_valid && expected_ready;

            /*
             * 输出端握手。
             */
            expected_output_fire =
                old_valid && downstream_ready;

            /*
             * 在下降沿改变输入。
             */
            @(negedge clk);

            i_valid = upstream_valid;
            i_data  = upstream_data;
            i_ready = downstream_ready;

            #1;

            /*
             * 检查时钟沿前的组合 ready。
             */
            if (o_ready !== expected_ready) begin
                report_error(
                    $sformatf(
                        "o_ready mismatch: expected=%0b actual=%0b",
                        expected_ready,
                        o_ready
                    )
                );
            end

            /*
             * 检查旧状态是否仍然正确。
             */
            if (o_valid !== old_valid) begin
                report_error(
                    $sformatf(
                        "o_valid changed before active edge: expected=%0b actual=%0b",
                        old_valid,
                        o_valid
                    )
                );
            end

            if (
                old_valid &&
                (o_data !== old_data)
            ) begin
                report_error(
                    $sformatf(
                        "o_data changed before active edge: expected=0x%0h actual=0x%0h",
                        old_data,
                        o_data
                    )
                );
            end

            /*
             * 如果输出端发生握手，下游应得到旧数据。
             */
            if (
                expected_output_fire &&
                (o_data !== old_data)
            ) begin
                report_error(
                    $sformatf(
                        "transferred data mismatch: expected=0x%0h actual=0x%0h",
                        old_data,
                        o_data
                    )
                );
            end

            /*
             * DUT 在上升沿更新寄存器。
             */
            @(posedge clk);
            #1;

            /*
             * 更新参考模型。
             */
            case ({
                expected_input_fire,
                expected_output_fire
            })
                /*
                 * 只接收上游数据。
                 */
                2'b10: begin
                    model_valid = 1'b1;
                    model_data  = upstream_data;
                end

                /*
                 * 只向下游输出旧数据。
                 */
                2'b01: begin
                    model_valid = 1'b0;
                end

                /*
                 * 旧数据输出，同时装入新数据。
                 */
                2'b11: begin
                    model_valid = 1'b1;
                    model_data  = upstream_data;
                end

                /*
                 * 没有握手，保持状态。
                 */
                default: begin
                    model_valid = old_valid;
                    model_data  = old_data;
                end
            endcase

            check_state();
        end
    endtask

    initial begin
        $dumpfile("rv_buffer_1entry.vcd");
        $dumpvars(0, tb_rv_buffer_1entry);

        resetn = 1'b1;

        i_valid = 1'b0;
        i_data  = '0;
        i_ready = 1'b0;

        model_valid = 1'b0;
        model_data  = '0;

        error_count = 0;

        $display("[RV] asynchronous reset");
        apply_reset();

        /*
         * 缓冲器为空，即使下游没有准备好，
         * 也能接收上游的第一个数据。
         */
        $display(
            "[RV] accept while downstream is stalled"
        );

        buffer_step(
            1'b1,
            8'h11,
            1'b0
        );

        /*
         * 下游持续阻塞。
         *
         * 缓冲器必须保持原来的 0x11，
         * 不能被 0xEE 覆盖。
         */
        $display("[RV] hold data under backpressure");

        buffer_step(
            1'b0,
            8'h00,
            1'b0
        );

        buffer_step(
            1'b1,
            8'hEE,
            1'b0
        );

        /*
         * 下游取走旧数据，但上游没有新数据，
         * 缓冲器变空。
         */
        $display("[RV] drain without replacement");

        buffer_step(
            1'b0,
            8'h00,
            1'b1
        );

        /*
         * 空缓冲器接收新数据。
         */
        $display("[RV] accept into empty buffer");

        buffer_step(
            1'b1,
            8'h22,
            1'b0
        );

        /*
         * 连续替换测试。
         *
         * 每个周期旧数据被下游取走，
         * 同时新数据进入缓冲器。
         */
        $display(
            "[RV] simultaneous output/input replacement"
        );

        buffer_step(1'b1, 8'h33, 1'b1);
        buffer_step(1'b1, 8'h44, 1'b1);
        buffer_step(1'b1, 8'h55, 1'b1);

        /*
         * 取走最后一个数据。
         */
        $display("[RV] final drain");

        buffer_step(
            1'b0,
            8'h00,
            1'b1
        );

        /*
         * 随机 valid-ready 测试。
         */
        $display("[RV] randomized regression");

        repeat (300) begin
            buffer_step(
                ($urandom_range(0, 1) != 0),
                DATA_WIDTH'($urandom),
                ($urandom_range(0, 1) != 0)
            );
        end

        /*
         * 如果随机测试结束后仍有数据，
         * 将其取出。
         */
        if (model_valid) begin
            buffer_step(
                1'b0,
                '0,
                1'b1
            );
        end

        /*
         * 中途复位。
         */
        $display("[RV] mid-stream reset");

        buffer_step(
            1'b1,
            8'hA5,
            1'b0
        );

        apply_reset();

        buffer_step(
            1'b1,
            8'h5A,
            1'b1
        );

        buffer_step(
            1'b0,
            '0,
            1'b1
        );

        if (error_count == 0) begin
            $display("========================================");
            $display("PASS: tb_rv_buffer_1entry");
            $display("========================================");
        end
        else begin
            $fatal(
                1,
                "FAIL: tb_rv_buffer_1entry, errors=%0d",
                error_count
            );
        end

        #10;
        $finish;
    end

endmodule
