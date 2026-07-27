`timescale 1ns/1ps
module tb_alu_random;

    localparam int unsigned WIDTH        = 8;

    localparam logic [3:0] OP_ADD  = 4'h0;
    localparam logic [3:0] OP_SUB  = 4'h1;
    localparam logic [3:0] OP_AND  = 4'h2;
    localparam logic [3:0] OP_OR   = 4'h3;
    localparam logic [3:0] OP_XOR  = 4'h4;
    localparam logic [3:0] OP_SLT  = 4'h5;
    localparam logic [3:0] OP_SLTU = 4'h6;
    localparam logic [3:0] OP_SHL  = 4'h7;
    localparam logic [3:0] OP_SHR  = 4'h8;

    localparam int unsigned RANDOM_TESTS = 5000;

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [3:0]       op;

    logic [WIDTH-1:0] result;
    logic             zero;
    logic             carry;
    logic             overflow;

int unsigned test_count;
int unsigned error_count;
int unsigned seed;
int unsigned seed_used;
logic [WIDTH-1:0]random_a;
logic [WIDTH-1:0]random_b;
logic [3:0]random_op;

ALU #(
        .WIDTH(WIDTH)
    ) dut (
        .a        (a),
        .b        (b),
        .op       (op),
        .result   (result),
        .zero     (zero),
        .carry    (carry),
        .overflow (overflow)
    );

task automatic reference_model(
    input  logic [WIDTH-1:0] ref_a,
        input  logic [WIDTH-1:0] ref_b,
        input  logic [3:0]       ref_op,

        output logic [WIDTH-1:0] expected_result,
        output logic             expected_zero,
        output logic             expected_carry,
        output logic             expected_overflow
);
    begin
            expected_result   = '0;
            expected_zero     = 1'b1;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;

            if(ref_op==OP_ADD)begin
                expected_result=ref_a+ref_b;
                expected_carry = (expected_result < ref_a);
                expected_overflow =(ref_a[WIDTH-1] == ref_b[WIDTH-1])&&(expected_result[WIDTH-1] != ref_a[WIDTH-1]);
            end
            else if(ref_op==OP_SUB)begin
                expected_result = ref_a - ref_b;
                expected_carry = (ref_a >= ref_b);
                expected_overflow =(ref_a[WIDTH-1] != ref_b[WIDTH-1])&&(expected_result[WIDTH-1] != ref_a[WIDTH-1]);
            end
            else if(ref_op==OP_AND)expected_result = ref_a & ref_b;
            else if (ref_op == OP_OR)expected_result = ref_a | ref_b;
            else if (ref_op == OP_XOR)expected_result = ref_a ^ ref_b;
            else if(ref_op==OP_SLT)begin
                expected_result='0;
                expected_result[0]=($signed(ref_a))<($signed(ref_b));
            end
            else if(ref_op==OP_SLTU)begin
                expected_result='0;
                expected_result[0]=(ref_a<ref_b);
            end
            else if (ref_op == OP_SHL) expected_result = ref_a << 1;
            else if (ref_op == OP_SHR) expected_result = ref_a >> 1;
            else expected_result = '0;

             expected_zero = (expected_result == '0);
    end
endtask
task automatic check_alu(
    input logic [WIDTH-1:0] test_a,
    input logic [WIDTH-1:0] test_b,
    input logic [3:0]       test_op
);
        logic [WIDTH-1:0] expected_result;
        logic             expected_zero;
        logic             expected_carry;
        logic             expected_overflow;
begin
    a=test_a;
    b=test_b;
    op=test_op;
    #1;
    reference_model(
        test_a,
        test_b,
        test_op,
        expected_result,
        expected_zero,
        expected_carry,
        expected_overflow
    );
    test_count=test_count+1;
    if({result, zero, carry, overflow}!=={
            expected_result,
            expected_zero,
            expected_carry,
            expected_overflow})begin

                error_count=error_count+1;
              $display("");
                $display(
                    "[ERROR %0d] test_count=%0d",
                    error_count,
                    test_count
                );

                $display(
                    "INPUT : a=0x%0h, b=0x%0h, op=0x%0h",
                    test_a,
                    test_b,
                    test_op
                );

                $display(
                    "DUT   : result=0x%0h, zero=%0b, carry=%0b, overflow=%0b",
                    result,
                    zero,
                    carry,
                    overflow
                );

                $display(
                    "REF   : result=0x%0h, zero=%0b, carry=%0b, overflow=%0b",
                    expected_result,
                    expected_zero,
                    expected_carry,
                    expected_overflow
                );

     end
end
endtask

initial begin
    a='0;
    b='0;
    op='0;
    test_count=0;
    error_count=0;

seed=32'd20061201;
if($value$plusargs("SEED=%d",seed))begin
    $display("Use command-line random seed.");
end
else begin
    $display("Use default random seed.");
end
seed_used = seed;
void'($urandom(seed));

$display("");
        $display("========================================");
        $display("ALU self-checking test start");
        $display("WIDTH = %0d", WIDTH);
        $display("RANDOM_TESTS = %0d", RANDOM_TESTS);
        $display("SEED = %0d", seed_used);
        $display("========================================");


 check_alu(
            8'h00,
            8'h00,
            OP_ADD
        );

        check_alu(
            8'hFF,
            8'h01,
            OP_ADD
        );

        check_alu(
            8'h7F,
            8'h01,
            OP_ADD
        );

        check_alu(
            8'h80,
            8'h80,
            OP_ADD
        );

        check_alu(
            8'h05,
            8'h03,
            OP_SUB
        );

        check_alu(
            8'h03,
            8'h05,
            OP_SUB
        );

        check_alu(
            8'h80,
            8'h01,
            OP_SUB
        );

        check_alu(
            8'hA5,
            8'h3C,
            OP_AND
        );

        check_alu(
            8'hA5,
            8'h3C,
            OP_OR
        );

        check_alu(
            8'hA5,
            8'h3C,
            OP_XOR
        );

        check_alu(
            8'h80,
            8'h7F,
            OP_SLT
        );

        check_alu(
            8'h80,
            8'h7F,
            OP_SLTU
        );

        check_alu(
            8'hA5,
            8'h00,
            OP_SHL
        );

        check_alu(
            8'hA5,
            8'h00,
            OP_SHR
        );

        check_alu(
            8'h12,
            8'h34,
            4'hF
        );

        //下面为5000组随机测试
        repeat(RANDOM_TESTS)begin
            random_a=WIDTH'($urandom());
            random_b=WIDTH'($urandom());
            random_op=4'($urandom_range(8,0));
            check_alu(.test_a(random_a),.test_b(random_b),.test_op(random_op));

        end

     $display("");
        $display("========================================");
        $display("ALU self-checking test finished");
        $display("SEED = %0d", seed_used);
        $display("TOTAL TESTS = %0d", test_count);
        $display("ERRORS = %0d", error_count);

        if (error_count == 0) begin
            $display("RESULT = PASS");
        end
        else begin
            $display("RESULT = FAIL");
        end

        $display("========================================");


        if (error_count!=0) begin
            $fatal(1,"ALU test failed with %0d errors.",error_count);
        end

        $finish;
end
endmodule
