module tb_and_gate;

    timeunit 1ns;
    timeprecision 1ps;

    logic a;
    logic b;
    logic y;

    and_gate dut (
        .a (a),
        .b (b),
        .y (y)
    );

    task automatic check(
        input logic test_a,
        input logic test_b,
        input logic expected
    );
        a = test_a;
        b = test_b;

        #1ns;

        if (y !== expected) begin
            $fatal(
                1,
                "TEST FAILED: a=%0b, b=%0b, expected=%0b, actual=%0b",
                a,
                b,
                expected,
                y
            );
        end
    endtask

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, tb_and_gate);

        check(1'b0, 1'b0, 1'b0);
        check(1'b0, 1'b1, 1'b0);
        check(1'b1, 1'b0, 1'b0);
        check(1'b1, 1'b1, 1'b1);

        $display("TEST PASS");
        $finish;
    end

endmodule
