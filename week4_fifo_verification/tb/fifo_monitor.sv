class fifo_monitor;
    virtual fifo_if vif;
    mailbox #(fifo_transaction) mon2scb;
    function new(
        virtual fifo_if vif,
        mailbox #(fifo_transaction) mon2scb
    );
    this.vif = vif;
    this.mon2scb = mon2scb;
    endfunction
    task run();
        fifo_transaction tr;
        forever begin
            @(posedge vif.clk);
            tr=new();
            tr.write = vif.wren;
        tr.read  = vif.rden;
        tr.data  = vif.wdata;
        tr.rdata = vif.rdata;
        tr.empty = vif.empty;
        tr.full  = vif.full;
        tr.count = int'(vif.count);
            mon2scb.put(tr);
        end
    endtask
endclass
