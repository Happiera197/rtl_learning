module tb_rv_buffer_1entry;

    localparam int WIDTH = 8;

    logic             clk;
    logic             resetn;
    logic             s_valid;
    logic             s_ready;
    logic [WIDTH-1:0] s_data;
    logic             m_valid;
    logic             m_ready;
    logic [WIDTH-1:0] m_data;

    int checks;
    int errors;
    int input_handshakes;
    int output_handshakes;

    logic [WIDTH-1:0] expected_q[$];
    logic [WIDTH-1:0] expected_data;

    rv_buffer_1entry #(
        .WIDTH(WIDTH)
    ) dut (
        .clk     (clk),
        .resetn  (resetn),
        .s_valid (s_valid),
        .s_ready (s_ready),
        .s_data  (s_data),
        .m_valid (m_valid),
        .m_ready (m_ready),
        .m_data  (m_data)
    );

    rv_assertions #(
        .WIDTH(WIDTH)
    ) assertions (
        .clk     (clk),
        .resetn  (resetn),
        .s_valid (s_valid),
        .s_ready (s_ready),
        .s_data  (s_data),
        .m_valid (m_valid),
        .m_ready (m_ready),
        .m_data  (m_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!resetn) begin
            expected_q.delete();
        end else begin
            if (m_valid && m_ready) begin
                output_handshakes++;
                checks++;

                if (expected_q.size() == 0) begin
                    errors++;
                    $error("Unexpected output handshake: m_data=0x%0h", m_data);
                end else begin
                    expected_data = expected_q.pop_front();
                    if (m_data !== expected_data) begin
                        errors++;
                        $error("Scoreboard mismatch: expected=0x%0h actual=0x%0h",
                               expected_data, m_data);
                    end
                end
            end

            if (s_valid && s_ready) begin
                input_handshakes++;
                expected_q.push_back(s_data);
            end
        end
    end

    task automatic check_bit(
        input logic  actual,
        input logic  expected,
        input string message
    );
        checks++;
        if (actual !== expected) begin
            errors++;
            $error("%s: expected=%0b actual=%0b", message, expected, actual);
        end
    endtask

    task automatic check_data(
        input logic [WIDTH-1:0] actual,
        input logic [WIDTH-1:0] expected,
        input string            message
    );
        checks++;
        if (actual !== expected) begin
            errors++;
            $error("%s: expected=0x%0h actual=0x%0h", message, expected, actual);
        end
    endtask

    task automatic check_int(
        input int    actual,
        input int    expected,
        input string message
    );
        checks++;
        if (actual != expected) begin
            errors++;
            $error("%s: expected=%0d actual=%0d", message, expected, actual);
        end
    endtask

    task automatic reset_dut();
        @(negedge clk);
        resetn = 1'b0;
        s_valid = 1'b0;
        s_data  = '0;
        m_ready = 1'b0;

        repeat (2) begin
            @(posedge clk);
            #1;
        end
        check_bit(m_valid, 1'b0, "m_valid during reset");

        @(negedge clk);
        resetn = 1'b1;

        @(posedge clk);
        #1;
        check_bit(m_valid, 1'b0, "m_valid after reset");
    endtask

    task automatic send_word(input logic [WIDTH-1:0] data);
        bit accepted;
        int cycle;

        accepted = 1'b0;
        @(negedge clk);
        s_valid = 1'b1;
        s_data  = data;

        for (cycle = 0; cycle < 20; cycle++) begin
            @(posedge clk);
            if (s_valid && s_ready) begin
                accepted = 1'b1;
                break;
            end
        end

        #1;
        check_bit(accepted, 1'b1, "input handshake timeout");

        @(negedge clk);
        s_valid = 1'b0;
        s_data  = '0;
    endtask

    task automatic test_reset();
        $display("TEST: reset");
        reset_dut();
    endtask

    task automatic test_single_transfer();
        int output_before;

        $display("TEST: single transfer");
        reset_dut();
        output_before = output_handshakes;
        m_ready = 1'b1;

        send_word(8'hA5);
        check_bit(m_valid, 1'b1, "single transfer m_valid");
        check_data(m_data, 8'hA5, "single transfer m_data");

        @(posedge clk);
        @(negedge clk);
        check_int(output_handshakes - output_before, 1,
                  "single transfer output handshake count");
        check_bit(m_valid, 1'b0, "single transfer buffer empty");
    endtask

    task automatic test_backpressure();
        int output_before;
        int cycle;

        $display("TEST: backpressure");
        reset_dut();
        output_before = output_handshakes;

        send_word(8'h3C);

        for (cycle = 0; cycle < 3; cycle++) begin
            check_bit(m_valid, 1'b1, "backpressure holds m_valid");
            check_data(m_data, 8'h3C, "backpressure holds m_data");
            @(posedge clk);
            @(negedge clk);
        end

        m_ready = 1'b1;
        #1;
        check_data(m_data, 8'h3C, "backpressure release data");

        @(posedge clk);
        @(negedge clk);
        check_int(output_handshakes - output_before, 1,
                  "backpressure output handshake count");
        check_bit(m_valid, 1'b0, "backpressure buffer empty");
    endtask

    task automatic test_full_stall();
        int input_before;
        int output_before;
        int cycle;

        $display("TEST: full buffer stall");
        reset_dut();
        input_before  = input_handshakes;
        output_before = output_handshakes;

        send_word(8'hC3);

        s_valid = 1'b1;
        s_data  = 8'h5A;
        #1;

        for (cycle = 0; cycle < 3; cycle++) begin
            check_bit(s_ready, 1'b0, "full buffer drives s_ready low");
            check_bit(m_valid, 1'b1, "full buffer holds m_valid");
            check_data(m_data, 8'hC3, "full buffer keeps old data");
            @(posedge clk);
            @(negedge clk);
        end

        m_ready = 1'b1;
        #1;
        check_bit(s_ready, 1'b1, "full buffer accepts replacement");
        check_data(m_data, 8'hC3, "old data before replacement handshake");

        @(posedge clk);
        @(negedge clk);
        s_valid = 1'b0;
        s_data  = '0;
        check_bit(m_valid, 1'b1, "replacement remains valid");
        check_data(m_data, 8'h5A, "replacement data stored");

        @(posedge clk);
        @(negedge clk);
        check_int(input_handshakes - input_before, 2,
                  "full stall input handshake count");
        check_int(output_handshakes - output_before, 2,
                  "full stall output handshake count");
        check_bit(m_valid, 1'b0, "full stall buffer empty");
    endtask

    task automatic test_stall_then_ready();
        int output_before;
        int cycle;

        $display("TEST: stall then ready");
        reset_dut();
        output_before = output_handshakes;

        send_word(8'h7D);

        for (cycle = 0; cycle < 2; cycle++) begin
            check_bit(m_valid, 1'b1, "stall recovery holds m_valid");
            check_data(m_data, 8'h7D, "stall recovery holds m_data");
            @(posedge clk);
            @(negedge clk);
        end

        m_ready = 1'b1;
        #1;
        check_data(m_data, 8'h7D, "stall recovery first output");
        @(posedge clk);
        @(negedge clk);
        check_bit(m_valid, 1'b0, "stall recovery released old data");

        send_word(8'hE7);
        check_bit(m_valid, 1'b1, "stall recovery accepts new data");
        check_data(m_data, 8'hE7, "stall recovery new data");
        @(posedge clk);
        @(negedge clk);

        check_int(output_handshakes - output_before, 2,
                  "stall recovery output handshake count");
        check_bit(m_valid, 1'b0, "stall recovery buffer empty");
    endtask

    task automatic test_continuous_transfer();
        logic [WIDTH-1:0] words [0:3];
        int input_before;
        int output_before;
        int index;

        $display("TEST: continuous transfer");
        words[0] = 8'h11;
        words[1] = 8'h22;
        words[2] = 8'h33;
        words[3] = 8'h44;

        reset_dut();
        input_before  = input_handshakes;
        output_before = output_handshakes;
        m_ready = 1'b1;

        @(negedge clk);
        s_valid = 1'b1;
        s_data  = words[0];

        for (index = 0; index < 4; index++) begin
            @(posedge clk);
            #1;
            check_bit(s_valid && s_ready, 1'b1,
                      "continuous input handshake");

            if (index < 3) begin
                @(negedge clk);
                s_data = words[index + 1];
            end
        end

        @(negedge clk);
        s_valid = 1'b0;
        s_data  = '0;
        check_bit(m_valid, 1'b1, "continuous final output valid");
        check_data(m_data, 8'h44, "continuous final output data");

        @(posedge clk);
        @(negedge clk);
        check_int(input_handshakes - input_before, 4,
                  "continuous input handshake count");
        check_int(output_handshakes - output_before, 4,
                  "continuous output handshake count");
        check_int(expected_q.size(), 0, "continuous scoreboard empty");
        check_bit(m_valid, 1'b0, "continuous buffer empty");
    endtask

    initial begin
        resetn           = 1'b0;
        s_valid          = 1'b0;
        s_data           = '0;
        m_ready          = 1'b0;
        checks           = 0;
        errors           = 0;
        input_handshakes = 0;
        output_handshakes = 0;

        test_reset();
        test_single_transfer();
        test_backpressure();
        test_full_stall();
        test_stall_then_ready();
        test_continuous_transfer();

        $display("========================================");
        $display("Ready/Valid Verification Summary");
        $display("Checks : %0d", checks);
        $display("Errors : %0d", errors);

        if (errors == 0) begin
            $display("RESULT : PASS");
        end else begin
            $display("RESULT : FAIL");
            $display("========================================");
            $fatal(1, "Ready/Valid verification failed");
        end

        $display("========================================");
        $finish;
    end

endmodule
