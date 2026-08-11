
class fifo_driver;
virtual fifo_if vif;
mailbox #(fifo_transaction) gen2drv;
    event drv_done;
    function new(
        virtual fifo_if vif,
        mailbox #(fifo_transaction) gen2drv,
        event drv_done
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.drv_done = drv_done;
    endfunction
task run();
    fifo_transaction tr;
    forever begin
        gen2drv.get(tr);
        @(negedge vif.clk);

        tr.display("DRV");

        vif.wren  = tr.write;
        vif.rden  = tr.read;
        vif.wdata = tr.data;
        @(posedge vif.clk);
        vif.wren = 1'b0;
        vif.rden = 1'b0;
        -> drv_done;
    end
endtask
endclass
