class fifo_scoreboard;
    mailbox #(fifo_transaction)mon2scb;
    bit [7:0] ref_queue[$];
    int checks;
    int errors;
    function new(
        mailbox #(fifo_transaction) mon2scb
    );
        this.mon2scb = mon2scb;
        checks = 0;
        errors = 0;
    endfunction

task run();
    fifo_transaction tr;
    bit [7:0] expected;
    forever begin
        mon2scb.get(tr);
        if (tr.write && !tr.full) begin
                ref_queue.push_back(tr.data);
            end
        if (tr.read && !tr.empty) begin

                expected = ref_queue.pop_front();

                checks++;

                if (tr.rdata !== expected) begin
                    errors++;
                    $error(
                        "FIFO mismatch: expected=%0h actual=%0h",
                        expected,
                        tr.rdata
                    );
                end

    end
    end
endtask
endclass
