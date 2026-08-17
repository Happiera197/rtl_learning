module tb_temporal_sequences;

    logic clk;
    logic resetn;

    logic req;
    logic ack;
    logic valid;
    logic [7:0] data;

    initial clk = 0;
    always #5 clk = ~clk;

    sequence s_req_ack;
        $rose(req) ##1 ack;
    endsequence

    c_req_ack: cover property (
        @(posedge clk)  disable iff (!resetn) s_req_ack);

    sequence s_valid_3;
         valid[*3];
    endsequence

    c_valid_3: cover property (
        @(posedge clk) disable iff (!resetn) s_valid_3);

    sequence s_wait_act_1to3;
        !ack[*0:2] ##1 ack;
    endsequence

    c_wait_act_1to3: cover property (
        @(posedge clk) disable iff (!resetn) s_wait_act_1to3);
endmodule
