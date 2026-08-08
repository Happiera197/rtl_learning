`timescale 1ns/1ps
module tb_sync_fifo;
localparam int unsigned WIDTH = 8;
localparam int unsigned DEPTH = 16;
localparam int unsigned COUNT_WIDTH = $clog2(DEPTH+1);

logic clk;
logic resetn;

logic wr_en;
logic rd_en;

logic [WIDTH-1:0] wr_data;
logic [WIDTH-1:0] rd_data;

logic empty;
logic full;
logic [COUNT_WIDTH-1:0] count;

sync_fifo #(
    .DATA_DEPTH(DEPTH),
    .DATA_WIDTH(WIDTH)
)dut(
    .clk(clk),
    .resetn(resetn),
    .wren(wr_en),
    .rden(rd_en),
    .wdata(wr_data),
    .rdata(rd_data),
    .empty(empty),
    .full(full),
    .count(count)
    );

initial begin
    clk=1'b0;
end

always #5 clk=~clk;

logic [WIDTH-1:0]ref_q[$];

int unsigned error_count=0;
int unsigned check_count=0;
string test_name;
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
logic [COUNT_WIDTH-1:0]expected_count;
logic expected_empty;
logic expected_full;

expected_count=COUNT_WIDTH'(ref_q.size());
expected_empty=(ref_q.size()==0);
expected_full=(ref_q.size()==DEPTH);

check_count+=3;
if(count!==expected_count) begin
report_error(
    test_name,
    $sformatf(
        "count错误,期望=%0d,实际=%0d",
        expected_count,
        count)
);
end

if(full!==expected_full) begin
report_error(
    test_name,
    $sformatf(
        "full错误,期望=%0d,实际=%0d",
        expected_full,
        full)
);
end

if(empty!==expected_empty) begin
report_error(
    test_name,
    $sformatf(
        "empty错误,期望=%0d,实际=%0d",
        expected_empty,
        empty)
);
end
endtask

task reset_dut();
    ref_q.delete();
    resetn = 1'b0;
    wr_en  = 1'b0;
    rd_en  = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    resetn = 1'b1;
    @(negedge clk);
    check_model("reset");

endtask

task automatic write_data(
    input logic [WIDTH-1:0]data
);
    logic do_write;
    @(negedge clk);
    do_write=(ref_q.size() < DEPTH);
    wr_en  = 1'b1;
    rd_en  = 1'b0;
    wr_data=data;
     @(posedge clk);
     if(do_write) ref_q.push_back(data);
     @(negedge clk);
     wr_en=1'b0;


endtask

task automatic read_data();
logic [WIDTH-1:0] expected_data;
logic do_read;
@(negedge clk);
    do_read=(ref_q.size() > 0);
    wr_en  = 1'b0;
    rd_en  = 1'b1;

     @(posedge clk);
     if(do_read) expected_data=ref_q.pop_front();
     @(negedge clk);
     rd_en=1'b0;
     if(do_read)begin
        if(rd_data!==expected_data)begin
            report_error(
                "read_data",
                $sformatf(
                    "rd_data错误,期望=%0h,实际=%0h",
                    expected_data,
                    rd_data)
            );
        end
        check_count++;
     end

    endtask

    task automatic test_reset();
        reset_dut();
        check_model("test_reset");
    endtask

    task automatic test_empty_read();
        reset_dut();
        read_data();
        check_model("test_empty_read");
    endtask

    task automatic test_full_write();
        int unsigned i;
        reset_dut();
        for(i=0;i<DEPTH;i++) write_data(WIDTH'(i));
        check_model("test_full_write_before_overflow");
        write_data(WIDTH'(i+2));
        check_model("test_full_write_after_overflow");
        for (i = 0; i < DEPTH; i++) begin
        read_data();
    end
        check_model("test_full_write");
    endtask

    task automatic test_consecutive_rw();
        int unsigned i;
        reset_dut();
        for(i=0;i<5;i++) write_data(WIDTH'(i));
        for(i=0;i<5;i++) read_data();
        check_model("test_consecutive_rw");
    endtask

    task automatic simultaneous_rw_data(
    input logic [WIDTH-1:0] data
);
    logic do_write;
    logic do_read;
    logic [WIDTH-1:0] expected_data;

    @(negedge clk);

    do_write = (ref_q.size() < DEPTH);
    do_read  = (ref_q.size() > 0);

    wr_en   = 1'b1;
    rd_en   = 1'b1;
    wr_data = data;

    @(posedge clk);

    if (do_read)
        expected_data = ref_q.pop_front();

    if (do_write)
        ref_q.push_back(data);

    @(negedge clk);

    wr_en = 1'b0;
    rd_en = 1'b0;

    if (do_read) begin
        check_count++;

        if (rd_data !== expected_data) begin
            report_error(
                "simultaneous_rw_data",
                $sformatf(
                    "rd_data错误,期望=%0h,实际=%0h",
                    expected_data,
                    rd_data
                )
            );
        end
    end
    endtask

task automatic test_simultaneous_rw();
    int unsigned i;

    reset_dut();

    write_data(8'h10);
    write_data(8'h20);
    write_data(8'h30);

    for (i = 0; i < 6; i++) begin
        simultaneous_rw_data(WIDTH'(i + 8'h40));
    end

    check_model("test_simultaneous_rw");
endtask

    task automatic test_wraparound();
    int unsigned i;
    reset_dut();
    for (i = 0; i < DEPTH - 4; i++) write_data(WIDTH'(i));
    for (i = 0; i < DEPTH / 2; i++) read_data();
    for (i = 0; i < DEPTH / 2; i++) write_data(WIDTH'(DEPTH + i));
    while (ref_q.size() > 0) read_data();
    check_model("test_wraparound");
    endtask

    task automatic test_mid_reset();
    int unsigned i;
        reset_dut();
        for(i=0;i<5;i++) write_data(WIDTH'(i));
        reset_dut();
        check_model("test_mid_reset");
    endtask

    task automatic random_test(
    input int unsigned cycles
);
    int unsigned i;

    logic do_write;
    logic do_read;
    logic [WIDTH-1:0] expected_data;

    reset_dut();
    for(i=0;i<cycles;i++)begin

        wr_en=1'($urandom_range(0,1));
        rd_en=1'($urandom_range(0,1));
        wr_data=WIDTH'($urandom);


        do_read=rd_en&&(ref_q.size() > 0);
    do_write=wr_en&&((ref_q.size() < DEPTH)||do_read);
        @(posedge clk);
        if (do_read)
            expected_data = ref_q.pop_front();
        if (do_write)
            ref_q.push_back(wr_data);
        @(negedge clk);
        if (do_read) begin
            check_count++;
            if (rd_data !== expected_data) begin
                report_error(
                    "random_test",
                    $sformatf(
                        "cycle=%0d, rd_data错误,期望=%0h,实际=%0h",
                        i,
                        expected_data,
                        rd_data
                    )
                );
            end
    end
    check_model("random_test");
    end
    wr_en = 1'b0;
    rd_en = 1'b0;
    endtask

    initial begin
    resetn = 1'b1;
    wr_en  = 1'b0;
    rd_en  = 1'b0;
    wr_data = '0;

    error_count = 0;
    check_count = 0;

    if ($test$plusargs("TRACE")) begin
        $dumpfile("sync_fifo.fst");
        $dumpvars(0, tb_sync_fifo);
    end

    if (!$value$plusargs("TEST=%s", test_name))
        test_name = "basic";
    //新增内容
    /*
    test_reset();
    test_empty_read();
    test_full_write();
    test_consecutive_rw();
    test_simultaneous_rw();
    test_wraparound();
    test_mid_reset();

    random_test(10000);
*/
//修改为选择测试
case (test_name)

        "basic": begin
            test_consecutive_rw();
            test_wraparound();
        end

        "reset": begin
            test_reset();
            test_mid_reset();
        end

        "full_empty": begin
            test_empty_read();
            test_full_write();
        end

        "simultaneous_rw": begin
            test_simultaneous_rw();
        end

        "random": begin
            random_test(10000);
        end

        default: begin
            $fatal(
                1,
                "Unknown TEST=%s",
                test_name
            );
        end

    endcase
/*
    $display("==============================");
    $display("FIFO Verification Summary");
    $display("Checks : %0d", check_count);
    $display("Errors : %0d", error_count);

    if (error_count == 0)
        $display("RESULT : PASS");
    else
        $display("RESULT : FAIL");

    $display("==============================");

    $finish;
    */
    $display("");
    $display("========================================");
    $display("FIFO Verification Summary");
    $display("Test   : %s", test_name);
    $display("Checks : %0d", check_count);
    $display("Errors : %0d", error_count);

    if (error_count == 0) begin
        $display("RESULT : PASS");
        $display("========================================");
    end
    else begin
        $display("RESULT : FAIL");
        $display("========================================");

        $fatal(
            1,
            "Test %s failed with %0d errors",
            test_name,
            error_count
        );
    end

    #10;
    $finish;
end

endmodule
