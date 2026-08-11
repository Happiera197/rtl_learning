
class fifo_generator;
    mailbox #(fifo_transaction) gen2drv;
    event drv_done;
    event gen_done;
    function new(
        mailbox #(fifo_transaction) gen2drv,
        event drv_done,
    );
        this.gen2drv  = gen2drv;
        this.drv_done = drv_done;
    endfunction
task run();
fifo_transaction tr;

repeat(100)begin
    tr=new();
    assert(tr.randomize()!=0);
    tr.display("GEN");

    gen2drv.put(tr);
    @drv_done;

end

endtask

endclass
