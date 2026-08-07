`timescale 1ns/1ps
program automatic fifo_test #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DATA_DEPTH = 16
)(
    fifo_if fifo
);

 localparam int unsigned COUNT_WIDTH = $clog2(DATA_DEPTH + 1);
    localparam int unsigned PREFILL_NUM =
        (DATA_DEPTH <= 2) ? 1 : DATA_DEPTH / 2;

    typedef logic [DATA_WIDTH-1:0] data_t;

    data_t model_q[$];

    int unsigned error_count;
    int unsigned check_count;


    function automatic data_t make_data(input int unsigned index);
        make_data = data_t'(index * 37 + 32'h0000_005a);
    endfunction

    task automatic report_error(
        input string test_name,
        input string message
    );
        error_count++;

        $error(
            "[%0t] %s: %s",
            $time,
            test_name,
            message
        );
    endtask

    task automatic check_model(
        input string test_name
    );

        logic [COUNT_WIDTH-1:0] expected_count;
        logic expected_empty;
        logic expected_full;

        expected_count = COUNT_WIDTH'(model_q.size());
        expected_empty = (model_q.size() == 0);
        expected_full  = (model_q.size() == DATA_DEPTH);

        check_count+=3;
        if (fifo.tb_cb.count !== expected_count) begin
            report_error(
                test_name,
                $sformatf(
                    "count错误,期望=%0d,实际=%0d",
                    expected_count,
                    fifo.tb_cb.count
                )
            );
        end

        if (fifo.tb_cb.empty !== expected_empty) begin
            report_error(
                test_name,
                $sformatf(
                    "empty错误,期望=%0b,实际=%0b",
                    expected_empty,
                    fifo.tb_cb.empty
                )
            );
        end

        if (fifo.tb_cb.full !== expected_full) begin
            report_error(
                test_name,
                $sformatf(
                    "full错误,期望=%0b,实际=%0b",
                    expected_full,
                    fifo.tb_cb.full
                )
            );
        end
    endtask

    task automatic reset_fifo(
        input string test_name
    );
        model_q.delete();

        fifo.resetn = 1'b0;

        fifo.tb_cb.wren  <= 1'b0;
        fifo.tb_cb.rden  <= 1'b0;
        fifo.tb_cb.wdata <= '0;

        repeat (3) @(fifo.tb_cb);
        @(negedge fifo.clk);
        fifo.resetn = 1'b1;
        @(fifo.tb_cb);

        check_model(test_name);

        check_count++;

        if (fifo.tb_cb.rdata !== '0) begin
            report_error(
                test_name,
                $sformatf(
                    "复位后rdata应为0,实际=%0h",
                    fifo.tb_cb.rdata
                )
            );
        end

    endtask

    task automatic apply_cycle(
        input bit     req_write,
        input data_t  write_data,
        input bit     req_read,
        input string  test_name
    ); int unsigned size_before;

        bit expected_read_fire;
        bit expected_write_fire;

        data_t expected_read_data;
        data_t previous_rdata;


        size_before = model_q.size();

        expected_read_fire =
            req_read && (size_before != 0);

        expected_write_fire =
            req_write &&
            (
                (size_before < DATA_DEPTH) ||
                expected_read_fire
            );

        previous_rdata = fifo.tb_cb.rdata;

        if (expected_read_fire)
            expected_read_data = model_q[0];
        else
            expected_read_data = '0;

        fifo.tb_cb.wren  <= req_write;
        fifo.tb_cb.wdata <= write_data;
        fifo.tb_cb.rden  <= req_read;

        @(fifo.tb_cb);
        fifo.tb_cb.wren  <= 0;//由于前面写了 input #1step,这里必须禁止读写，否则DUT里面存入两份data
        fifo.tb_cb.rden  <= 0;
        @(fifo.tb_cb);

        check_count++;

        if (expected_read_fire) begin

            void'(model_q.pop_front());

            if (fifo.tb_cb.rdata !== expected_read_data) begin
                report_error(
                    test_name,
                    $sformatf(
                        "读取数据错误，期望=%0h,实际=%0h",
                        expected_read_data,
                        fifo.tb_cb.rdata
                    )
                );
            end

        end
        else begin

            if (fifo.tb_cb.rdata !== previous_rdata) begin
                report_error(
                    test_name,
                    $sformatf(
                        "未成功读取时rdata发生变化,原值=%0h,新值=%0h",
                        previous_rdata,
                        fifo.tb_cb.rdata
                    )
                );
            end

        end


        if (expected_write_fire)
            model_q.push_back(write_data);

        check_model(test_name);

    endtask

 task automatic finish_driving;

        fifo.tb_cb.wren  <= 1'b0;
        fifo.tb_cb.rden  <= 1'b0;
        fifo.tb_cb.wdata <= '0;

        @(fifo.tb_cb);

        check_model("最终空闲周期");

    endtask

//下面正式开始test
 initial begin : main_test

        int unsigned i;

        error_count = 0;
        check_count = 0;

        $display("========================================");
        $display("开始同步FIFO测试");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("DATA_DEPTH = %0d", DATA_DEPTH);
        $display("========================================");


        //1. 初始复位

        reset_fifo("初始复位");


        //2. 单次写入、单次读取

        apply_cycle(
            1'b1,
            make_data(1),
            1'b0,
            "单次写入"
        );

        apply_cycle(
            1'b0,
            '0,
            1'b1,
            "单次读取"
        );


        //3. 非空状态下再次异步复位

        for (i = 0; (i < 3) && (i < DATA_DEPTH); i++) begin
            apply_cycle(
                1'b1,
                make_data(10 + i),
                1'b0,
                $sformatf("复位前写入[%0d]", i)
            );
        end

        reset_fifo("非空状态异步复位");


        //4. 连续写入直到 full

        for (i = 0; i < DATA_DEPTH; i++) begin
            apply_cycle(
                1'b1,
                make_data(100 + i),
                1'b0,
                $sformatf("写满FIFO[%0d]", i)
            );
        end


        //5. full 状态下只写不读：
        apply_cycle(
            1'b1,
            make_data(1000),
            1'b0,
            "满状态写入阻止"
        );

        //6. full 状态下同时读写：

        apply_cycle(
            1'b1,
            make_data(1001),
            1'b1,
            "满状态同时读写"
        );


        //7. 连续读取直到 empty
        for (i = 0; i < DATA_DEPTH; i++) begin
            apply_cycle(
                1'b0,
                '0,
                1'b1,
                $sformatf("读空FIFO[%0d]", i)
            );
        end

        //8. empty 状态下只读：
        apply_cycle(
            1'b0,
            '0,
            1'b1,
            "空状态读取阻止"
        );


        //9. empty 状态下同时读写。

        apply_cycle(
            1'b1,
            make_data(2000),
            1'b1,
            "空状态同时读写"
        );

        apply_cycle(
            1'b0,
            '0,
            1'b1,
            "读取空状态同时写入的数据"
        );


        //10. 先放入一部分数据。

        for (i = 0; i < PREFILL_NUM; i++) begin
            apply_cycle(
                1'b1,
                make_data(3000 + i),
                1'b0,
                $sformatf("同时读写测试预填充[%0d]", i)
            );
        end


        //11. 连续同时读写。

        for (i = 0; i < DATA_DEPTH * 2; i++) begin
            apply_cycle(
                1'b1,
                make_data(4000 + i),
                1'b1,
                $sformatf("连续同时读写[%0d]", i)
            );
        end


        //12. 读取参考队列中剩余的数据。

        while (model_q.size() != 0) begin
            apply_cycle(
                1'b0,
                '0,
                1'b1,
                "读取剩余数据"
            );
        end

        finish_driving();

        $display("========================================");
        $display("FIFO测试结束");
        $display("检查次数：%0d", check_count);
        $display("错误数量：%0d", error_count);
        $display("========================================");

        if (error_count == 0) begin
            $display("FIFO TEST PASS");
            $finish;
        end
        else begin
            $fatal(
                1,
                "FIFO TEST FAIL,共发现%0d个错误",
                error_count
            );
        end

    end

endprogram
