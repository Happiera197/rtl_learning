`timescale 1ns/1ps

module tb_counter;

    localparam time CLK_PERIOD = 10ns;

    logic       clk;
    logic       resetn;
    logic       enable;
    logic [3:0] count;

    bit reset_seen;
    bit enable_seen;
    bit wrap_seen;

    counter dut (
        .clk    (clk),
        .resetn (resetn),
        .enable (enable),
        .count  (count)
    );

    initial begin
        clk = 1'b0;
    end

    always #(CLK_PERIOD / 2) clk = ~clk;

    property p_reset;
        @(posedge clk)
        !resetn |=> count == 4'd0;
    endproperty

    a_reset: assert property (p_reset)
        else $error("p_reset failed: count is not zero after reset");

    property p_enable;
        @(posedge clk)
        disable iff (!resetn)
        enable && count != 4'd15
        |=> count == $past(count) + 4'd1;
    endproperty

    a_enable: assert property (p_enable)
        else $error("p_enable failed: count did not increment by one");

    property p_wrap;
        @(posedge clk)
        disable iff (!resetn)
        enable && count == 4'd15
        |=> count == 4'd0;
    endproperty

    a_wrap: assert property (p_wrap)
        else $error("p_wrap failed: count did not wrap to zero");

    c_reset: cover property (@(posedge clk) !resetn)
        reset_seen = 1'b1;

    c_enable: cover property (
        @(posedge clk)
        disable iff (!resetn)
        enable && count != 4'd15
    ) enable_seen = 1'b1;

    c_wrap: cover property (
        @(posedge clk)
        disable iff (!resetn)
        enable && count == 4'd15
    ) wrap_seen = 1'b1;

    initial begin
        resetn = 1'b0;
        enable = 1'b0;

        repeat (2) @(negedge clk);
        resetn = 1'b1;

        @(negedge clk);
        enable = 1'b1;

        repeat (18) @(negedge clk);

        enable = 1'b0;

        @(posedge clk);
        #1ps;

        if (!reset_seen || !enable_seen || !wrap_seen)
            $fatal(1, "FAIL: not all assertion antecedents were exercised");

        $display("PASS: reset, enable/increment, and wrap scenarios passed.");
        $finish;
    end

endmodule
