module tb_ALU;

    timeunit 1ns;
    timeprecision 1ps;

    localparam int unsigned WIDTH = 8;

    typedef logic [WIDTH-1:0] data_t;
    typedef logic [3:0]       op_t;

    localparam logic [3:0] OP_ADD  = 4'h0;
    localparam logic [3:0] OP_SUB  = 4'h1;
    localparam logic [3:0] OP_AND  = 4'h2;
    localparam logic [3:0] OP_OR   = 4'h3;
    localparam logic [3:0] OP_XOR  = 4'h4;
    localparam logic [3:0] OP_SLT  = 4'h5;
    localparam logic [3:0] OP_SLTU = 4'h6;
    localparam logic [3:0] OP_SHL  = 4'h7;
    localparam logic [3:0] OP_SHR  = 4'h8;

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [3:0]       op;

    logic [WIDTH-1:0] result;
    logic             zero;
    logic             carry;
    logic             overflow;

    int unsigned test_count;
    int unsigned error_count;

    /*
     * 一些常用边界值。
     *
     * WIDTH=8 时：
     * ZERO_VALUE = 8'h00
     * ONE_VALUE  = 8'h01
     * ALL_ONES   = 8'hFF
     * MAX_POS    = 8'h7F，即有符号数 127
     * MIN_NEG    = 8'h80，即有符号数 -128
     */
initial begin
    $dumpfile("build/alu.vcd");
    $dumpvars(0, tb_ALU);
end

    localparam logic [WIDTH-1:0] ZERO_VALUE = '0;

    localparam logic [WIDTH-1:0] ONE_VALUE =
        {{(WIDTH-1){1'b0}}, 1'b1};

    localparam logic [WIDTH-1:0] ALL_ONES = '1;

    localparam logic [WIDTH-1:0] MAX_POS =
        {1'b0, {(WIDTH-1){1'b1}}};

    localparam logic [WIDTH-1:0] MIN_NEG =
        {1'b1, {(WIDTH-1){1'b0}}};

    /*
     * 实例化待测 ALU。
     */
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

    /*
     * 单次自动检查任务。
     *
     * 每调用一次：
     * 1. 给 DUT 输入赋值；
     * 2. Testbench 自己计算正确答案；
     * 3. 等待组合逻辑稳定；
     * 4. 比较所有输出。
     */
    task automatic check_one(
        input logic [WIDTH-1:0] test_a,
        input logic [WIDTH-1:0] test_b,
        input logic [3:0]       test_op
    );

        logic [WIDTH-1:0] expected_result;
        logic             expected_zero;
        logic             expected_carry;
        logic             expected_overflow;

        logic [WIDTH:0] expected_extended;

        begin
            /*
             * 先给参考结果设置默认值。
             * 非加减法中 carry、overflow 应保持为 0。
             */
            expected_result   = '0;
            expected_extended = '0;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;

            case (test_op)

                OP_ADD: begin
                    expected_extended =
                        {1'b0, test_a}
                        + {1'b0, test_b};

                    expected_result =
                        expected_extended[WIDTH-1:0];

                    expected_carry =
                        expected_extended[WIDTH];

                    expected_overflow =
                        ~(test_a[WIDTH-1] ^ test_b[WIDTH-1])
                        & (expected_result[WIDTH-1]
                           ^ test_a[WIDTH-1]);
                end

                OP_SUB: begin
                    /*
                     * a - b = a + (~b) + 1
                     *
                     * 减法中的 carry：
                     * carry=1 表示没有借位；
                     * carry=0 表示发生借位。
                     */
                    expected_extended =
                        {1'b0, test_a}
                        + {1'b0, ~test_b}
                        + {{WIDTH{1'b0}}, 1'b1};

                    expected_result =
                        expected_extended[WIDTH-1:0];

                    expected_carry =
                        expected_extended[WIDTH];

                    expected_overflow =
                        (test_a[WIDTH-1] ^ test_b[WIDTH-1])
                        & (expected_result[WIDTH-1]
                           ^ test_a[WIDTH-1]);
                end

                OP_AND: begin
                    expected_result = test_a & test_b;
                end

                OP_OR: begin
                    expected_result = test_a | test_b;
                end

                OP_XOR: begin
                    expected_result = test_a ^ test_b;
                end

                OP_SLT: begin
                    expected_result = '0;

                    expected_result[0] =
                        ($signed(test_a) < $signed(test_b));
                end

                OP_SLTU: begin
                    expected_result = '0;

                    expected_result[0] =
                        (test_a < test_b);
                end

                OP_SHL: begin
                    /*
                     * 与当前 ALU 规格一致：
                     * 固定逻辑左移一位。
                     */
                    expected_result = test_a << 1;
                end

                OP_SHR: begin
                    /*
                     * 与当前 ALU 规格一致：
                     * 固定逻辑右移一位。
                     */
                    expected_result = test_a >> 1;
                end

                default: begin
                    expected_result   = '0;
                    expected_carry    = 1'b0;
                    expected_overflow = 1'b0;
                end

            endcase

            expected_zero = (expected_result == '0);

            /*
             * 驱动 DUT 输入。
             */
            a  = test_a;
            b  = test_b;
            op = test_op;

            /*
             * ALU 是组合逻辑。
             * 等待一个很短的仿真时间，让输出更新。
             */
            #1ns;

            test_count++;

            /*
             * 使用 !== 而不是 !=。
             *
             * !== 可以把 X、Z 也检测为错误，
             * 避免未知值被漏掉。
             */
            if (
                (result   !== expected_result)
                || (zero     !== expected_zero)
                || (carry    !== expected_carry)
                || (overflow !== expected_overflow)
            ) begin

                error_count++;

                $display("");
                $display("========== ALU TEST FAILED ==========");
                $display("test number       = %0d", test_count);
                $display("op                = 0x%0h", test_op);
                $display("a                 = 0x%0h", test_a);
                $display("b                 = 0x%0h", test_b);

                $display("expected result   = 0x%0h",
                         expected_result);

                $display("actual result     = 0x%0h",
                         result);

                $display("expected zero     = %0b",
                         expected_zero);

                $display("actual zero       = %0b",
                         zero);

                $display("expected carry    = %0b",
                         expected_carry);

                $display("actual carry      = %0b",
                         carry);

                $display("expected overflow = %0b",
                         expected_overflow);

                $display("actual overflow   = %0b",
                         overflow);

                $display("=====================================");
                $display("");

                /*
                 * 当前选择发现第一个错误就停止，
                 * 便于定位问题。
                 */
                $fatal(1, "ALU self-check failed");
            end
        end
    endtask

    initial begin
        test_count  = 0;
        error_count = 0;

        a  = '0;
        b  = '0;
        op = '0;

        #1ns;

        $display("=====================================");
        $display("Starting ALU self-check");
        $display("WIDTH = %0d", WIDTH);
        $display("=====================================");

        /*
         * 第一部分：定向边界测试
         */

        // ADD
        check_one(ZERO_VALUE, ZERO_VALUE, OP_ADD);
        check_one(ONE_VALUE,  ONE_VALUE,  OP_ADD);
        check_one(ALL_ONES,   ONE_VALUE,  OP_ADD);
        check_one(MAX_POS,    ONE_VALUE,  OP_ADD);
        check_one(MIN_NEG,    ALL_ONES,   OP_ADD);
        check_one(MIN_NEG,    MIN_NEG,    OP_ADD);

        // SUB
        check_one(8'd5,       8'd3,       OP_SUB);
        check_one(8'd3,       8'd5,       OP_SUB);
        check_one(ZERO_VALUE, ONE_VALUE,  OP_SUB);
        check_one(ONE_VALUE,  ONE_VALUE,  OP_SUB);
        check_one(MAX_POS,    ALL_ONES,   OP_SUB);
        check_one(MIN_NEG,    ONE_VALUE,  OP_SUB);

        // AND
        check_one(8'b1010_1010, 8'b1100_1100, OP_AND);
        check_one(ALL_ONES,      ZERO_VALUE,   OP_AND);
        check_one(ALL_ONES,      ALL_ONES,     OP_AND);

        // OR
        check_one(8'b1010_1010, 8'b1100_1100, OP_OR);
        check_one(ZERO_VALUE,   ZERO_VALUE,    OP_OR);
        check_one(ALL_ONES,     ZERO_VALUE,    OP_OR);

        // XOR
        check_one(8'b1010_1010, 8'b1100_1100, OP_XOR);
        check_one(ALL_ONES,      ALL_ONES,     OP_XOR);
        check_one(ALL_ONES,      ZERO_VALUE,   OP_XOR);

        /*
         * signed 与 unsigned 比较的关键区别。
         *
         * 8'hFF：
         * signed   解释为 -1；
         * unsigned 解释为 255。
         */
        check_one(ALL_ONES, ONE_VALUE, OP_SLT);
        check_one(ALL_ONES, ONE_VALUE, OP_SLTU);

        check_one(MIN_NEG, MAX_POS, OP_SLT);
        check_one(MIN_NEG, MAX_POS, OP_SLTU);

        check_one(ONE_VALUE, ONE_VALUE, OP_SLT);
        check_one(ONE_VALUE, ONE_VALUE, OP_SLTU);

        // 固定移位一位
        check_one(8'b1000_0001, ZERO_VALUE, OP_SHL);
        check_one(8'b1000_0001, ZERO_VALUE, OP_SHR);
        check_one(ALL_ONES,     ZERO_VALUE, OP_SHL);
        check_one(ALL_ONES,     ZERO_VALUE, OP_SHR);
        check_one(ZERO_VALUE,   ZERO_VALUE, OP_SHL);
        check_one(ZERO_VALUE,   ZERO_VALUE, OP_SHR);

        // 非法操作码
        check_one(8'hA5, 8'h5A, 4'h9);
        check_one(8'hA5, 8'h5A, 4'hF);

        /*
         * 第二部分：随机测试。
         *
         * 9 种合法操作，每种测试 200 组：
         *
         * 9 × 200 = 1800 组随机输入
         */
       for (int op_index = 0; op_index <= 8; op_index++) begin
    for (int i = 0; i < 200; i++) begin
        data_t random_a;
        data_t random_b;

        random_a = data_t'($urandom());
        random_b = data_t'($urandom());

        check_one(
            random_a,
            random_b,
            op_t'(op_index)
        );
    end
end
        $display("");
        $display("=====================================");
        $display("ALU TEST PASSED");
        $display("total tests = %0d", test_count);
        $display("errors      = %0d", error_count);
        $display("=====================================");
        $display("");

        $finish;
    end

endmodule
