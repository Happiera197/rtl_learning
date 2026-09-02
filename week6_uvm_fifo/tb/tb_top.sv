module tb_top;
    import uvm_pkg::*;
    import fifo_pkg::*;

    logic clk;

    initial begin
            clk=0;
            forever #5 clk=~clk;
    end

    fifo_if#(.DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH)
    )vif(.clk(clk));

    sync_fifo#(.DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(DATA_DEPTH)
    ) dut(.clk(clk),
        .resetn(vif.resetn),
        .wren(vif.wren),
        .wdata(vif.wdata),
        .rden(vif.rden),
        .rdata(vif.rdata),
        .empty(vif.empty),
        .full(vif.full),
        .count(vif.count)
    );

    initial begin
    uvm_config_db#(fifo_vif_t)::set(null,"uvm_test_top.m_env.m_agent.*","vif",vif);
        run_test("fifo_test");
        end
endmodule
