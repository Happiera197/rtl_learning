`timescale 1ns/1ps

module tb_memory;

    // ============================================================
    // 时钟与RAM公共输入
    // ============================================================
    logic       clk;
    logic       we;
    logic [3:0] ram_addr;
    logic [7:0] wdata;

    // ============================================================
    // ROM信号
    // ============================================================
    logic [3:0] rom_addr;
    logic [7:0] rom_rdata;

    // ============================================================
    // 两种RAM的输出
    // ============================================================
    logic [7:0] async_rdata;
    logic [7:0] sync_rdata;

    integer i;

    // ============================================================
    // 例化16×8 ROM
    // ============================================================
    rom16x8 u_rom (
        .addr  (rom_addr),
        .rdata (rom_rdata)
    );

    // ============================================================
    // 例化异步读、同步写RAM
    // ============================================================
    ram16x8_async_read u_ram_async (
        .clk   (clk),
        .we    (we),
        .addr  (ram_addr),
        .wdata (wdata),
        .rdata (async_rdata)
    );

    // ============================================================
    // 例化同步读、同步写RAM
    // ============================================================
    ram16x8_sync_read u_ram_sync (
        .clk   (clk),
        .we    (we),
        .addr  (ram_addr),
        .wdata (wdata),
        .rdata (sync_rdata)
    );

    // ============================================================
    // 时钟：周期10 ns
    // ============================================================
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // ROM参考数据
    // ============================================================
    function automatic logic [7:0] expected_rom (
        input logic [3:0] addr
    );
        case (addr)
            4'h0: expected_rom = 8'h10;
            4'h1: expected_rom = 8'h21;
            4'h2: expected_rom = 8'h32;
            4'h3: expected_rom = 8'h43;
            4'h4: expected_rom = 8'h54;
            4'h5: expected_rom = 8'h65;
            4'h6: expected_rom = 8'h76;
            4'h7: expected_rom = 8'h87;
            4'h8: expected_rom = 8'h98;
            4'h9: expected_rom = 8'hA9;
            4'hA: expected_rom = 8'hBA;
            4'hB: expected_rom = 8'hCB;
            4'hC: expected_rom = 8'hDC;
            4'hD: expected_rom = 8'hED;
            4'hE: expected_rom = 8'hFE;
            4'hF: expected_rom = 8'h0F;
            default: expected_rom = 8'h00;
        endcase
    endfunction

    // ============================================================
    // 通用检查任务
    // ============================================================
    task automatic check_byte (
        input string      test_name,
        input logic [7:0] actual,
        input logic [7:0] expected
    );
        begin
            if (actual !== expected) begin
                $error(
                    "[FAIL] %s: actual=0x%02h, expected=0x%02h, time=%0t",
                    test_name,
                    actual,
                    expected,
                    $time
                );

                $fatal(1);
            end
            else begin
                $display(
                    "[PASS] %s: value=0x%02h, time=%0t",
                    test_name,
                    actual,
                    $time
                );
            end
        end
    endtask

    // ============================================================
    // 同时向两个RAM写入数据
    // 写入发生在时钟上升沿
    // ============================================================
    task automatic write_both_rams (
        input logic [3:0] address,
        input logic [7:0] data
    );
        begin
            // 在下降沿改变输入，保证到下一个上升沿前信号稳定
            @(negedge clk);

            we       = 1'b1;
            ram_addr = address;
            wdata    = data;

            // 等待真正写入
            @(posedge clk);
            #1;

            $display(
                "[WRITE] addr=0x%01h, data=0x%02h, time=%0t",
                address,
                data,
                $time
            );
        end
    endtask

    // ============================================================
    // 主测试流程
    // ============================================================
    initial begin
        // 生成波形文件
        $dumpfile("build/memory.vcd");
        $dumpvars(0, tb_memory);

        // 初始输入
        we        = 1'b0;
        ram_addr  = 4'h0;
        wdata     = 8'h00;
        rom_addr  = 4'h0;

        $display("");
        $display("========================================");
        $display(" Start ROM/RAM testbench");
        $display("========================================");

        // 给组合逻辑一点稳定时间
        #1;

        // ========================================================
        // 测试1：检查ROM全部16个地址
        // ========================================================
        $display("");
        $display("---- Test 1: ROM full-address test ----");

        for (i = 0; i < 16; i = i + 1) begin
            rom_addr = i[3:0];

            // ROM为异步读取，地址改变后等待少量组合逻辑延迟
            #1;

            check_byte(
                $sformatf("ROM address %0d", i),
                rom_rdata,
                expected_rom(i[3:0])
            );
        end

        // ========================================================
        // 测试2：初始化两种RAM
        // 每个地址写入 0x80 + 地址
        // ========================================================
        $display("");
        $display("---- Test 2: Initialize both RAMs ----");

        for (i = 0; i < 16; i = i + 1) begin
    write_both_rams(
        i[3:0],
        {4'h8, i[3:0]}
    );
end

        // 关闭写使能
        @(negedge clk);
        we       = 1'b0;
        wdata    = 8'h00;
        ram_addr = 4'h2;

        #1;

        // 异步读地址一改变就能读到数据
        check_byte(
            "Async RAM address 2",
            async_rdata,
            8'h82
        );

        // 同步RAM必须等待时钟上升沿
        @(posedge clk);
        #1;

        check_byte(
            "Sync RAM address 2 after clock edge",
            sync_rdata,
            8'h82
        );

        // ========================================================
        // 测试3：展示同步读比异步读晚一个时钟沿
        // ========================================================
        $display("");
        $display("---- Test 3: Async-read versus sync-read ----");

        @(negedge clk);

        // 从地址2切换到地址9
        ram_addr = 4'h9;

        #1;

        // 异步输出已经变为地址9中的数据
        check_byte(
            "Async RAM changes immediately to address 9",
            async_rdata,
            8'h89
        );

        // 同步输出还保持上一次时钟读取的地址2数据
        check_byte(
            "Sync RAM still holds previous result",
            sync_rdata,
            8'h82
        );

        // 等下一个上升沿，同步输出才更新
        @(posedge clk);
        #1;

        check_byte(
            "Sync RAM updates at next clock edge",
            sync_rdata,
            8'h89
        );

        // ========================================================
        // 测试4：同地址同时读写
        // 同步RAM应表现为read-first
        // ========================================================
        $display("");
        $display("---- Test 4: Same-address read/write ----");

        // 先正常读取地址4，旧数据应该是0x84
        @(negedge clk);

        we       = 1'b0;
        ram_addr = 4'h4;

        #1;

        check_byte(
            "Async RAM old data at address 4",
            async_rdata,
            8'h84
        );

        @(posedge clk);
        #1;

        check_byte(
            "Sync RAM old data at address 4",
            sync_rdata,
            8'h84
        );

        // 在下一上升沿向地址4写入0xE4
        @(negedge clk);

        we       = 1'b1;
        ram_addr = 4'h4;
        wdata    = 8'hE4;

        // 写入发生前，异步读仍然看到旧值
        #1;

        check_byte(
            "Async RAM before same-address write edge",
            async_rdata,
            8'h84
        );

        @(posedge clk);
        #1;

        // 异步RAM在写入完成后直接看到新值
        check_byte(
            "Async RAM after same-address write",
            async_rdata,
            8'hE4
        );

        // 同步RAM是read-first，同一拍输出旧值
        check_byte(
            "Sync RAM read-first old value",
            sync_rdata,
            8'h84
        );

        // 关闭写使能，再读一拍
        @(negedge clk);

        we       = 1'b0;
        ram_addr = 4'h4;

        @(posedge clk);
        #1;

        // 下一拍同步RAM才能读到新值
        check_byte(
            "Sync RAM new value on following read",
            sync_rdata,
            8'hE4
        );

        // ========================================================
        // 测试5：we=0时不能写入
        // ========================================================
        $display("");
        $display("---- Test 5: Write enable disabled ----");

        @(negedge clk);

        we       = 1'b0;
        ram_addr = 4'h6;
        wdata    = 8'hFF;

        @(posedge clk);
        #1;

        check_byte(
            "Async RAM unchanged when we=0",
            async_rdata,
            8'h86
        );

        check_byte(
            "Sync RAM unchanged when we=0",
            sync_rdata,
            8'h86
        );

        $display("");
        $display("========================================");
        $display(" All ROM/RAM tests passed");
        $display("========================================");
        $display("");

        $finish;
    end

endmodule
