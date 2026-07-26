`timescale 1ns/1ps
module tb_counter;
localparam int unsigned WIDTH = 4;
    logic clk;
    logic resetn;
    logic en;
    logic [WIDTH-1:0] count;
    logic [WIDTH-1:0] expected;

     counter  #(.WIDTH(WIDTH))
     dut (
        .clk   (clk),
        .resetn(resetn),
        .en    (en),
        .count (count)
    );

localparam time CLK_PERIOD = 10ns;
int unsigned cycle;

  initial begin
        clk = 1'b0;
    end

    always #(CLK_PERIOD / 2) clk <= ~clk;

task automatic apply_and_check (
    input logic next_resetn,
    input logic next_en
);
    begin
        @(negedge clk);
        resetn=next_resetn;
        en=next_en;
        @(posedge clk);
        #1ps;
        cycle=cycle+1;

        if(!next_resetn)expected='0;
        else if(next_en)expected=expected+1'b1;

        if(count!==expected)begin
            $fatal(1,"FAIL: cycle=%0d, resetn=%0b, en=%0b, expected=0x%0h, actual=0x%0h",
                    cycle,
                    next_resetn,
                    next_en,
                    expected,
                    count);
        end
    end
endtask

initial begin
    resetn=1'b0;
    en=1'b0;
    expected='0;
    cycle=0;
    repeat(2)begin
        apply_and_check(1'b0,1'b0);
    end
    repeat(2)begin
        apply_and_check(1'b1,1'b0);
    end

    repeat(10)begin
        apply_and_check(1'b1,1'b1);
    end

    repeat(5)begin
        apply_and_check(1'b1,1'b0);
    end

    repeat((1<<WIDTH)+2)begin
        apply_and_check(1'b1,1'b1);
    end
     $display(
            "PASS: all %0d checked cycles passed.",
            cycle
        );

        $finish;
end


endmodule
