class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp#(fifo_item,fifo_scoreboard)ap;
    bit [DATA_WIDTH-1:0] model_queue[$];
    int unsigned checks;
    int unsigned errors;
    function new(string name,uvm_component parent);
        super.new(name,parent);
        ap=new("ap",this);
        checks=0;
        errors=0;
    endfunction
    virtual function void write(fifo_item tr);
        bit [DATA_WIDTH-1:0] expected_data;
        bit model_full;
        bit model_empty;
        bit read_success;
        bit write_success;

        if(!tr.resetn)begin
            model_queue.delete();
            if(tr.count!=0)begin
                `uvm_error("SCB",$sformatf("RESET: count should be 0, actual=%0d",tr.count))
                errors++;
            end
            if(!tr.empty)begin
                `uvm_error("SCB",$sformatf("RESET: empty should be 1, actual=%0d",tr.empty))
                errors++;
            end
            if(tr.full!=0)begin
                `uvm_error("SCB",$sformatf("RESET: full should be 0, actual=%0d",tr.full))
                errors++;
            end
            return;
        end

        model_full = (model_queue.size() == DATA_DEPTH);
        model_empty = (model_queue.size() == 0);
        read_success = tr.rden && !model_empty;
        write_success = tr.wren && (!model_full||read_success);

        if(read_success)begin
            expected_data = model_queue.pop_front();
            checks++;
            if(tr.rdata!=expected_data)begin
                `uvm_error("SCB",$sformatf("READ ERROR: expected=%0h actual=%0h",expected_data,tr.rdata))
                errors++;
            end
        end

        if(write_success)begin
            model_queue.push_back(tr.wdata);

        end
        checks++;
        if(tr.count!=model_queue.size())begin
            `uvm_error("SCB",$sformatf("COUNT ERROR: expected=%0d actual=%0d",model_queue.size(),tr.count))
            errors++;
        end
        checks++;
        if(tr.empty!=(model_queue.size() == 0))begin
            `uvm_error("SCB",$sformatf("EMPTY ERROR: expected=%0d actual=%0d",(model_queue.size() == 0),tr.empty))
            errors++;
        end
        checks++;
        if(tr.full!=(model_queue.size() == DATA_DEPTH))begin
            `uvm_error("SCB",$sformatf("FULL ERROR: expected=%0d actual=%0d",(model_queue.size() == DATA_DEPTH),tr.full))
            errors++;
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if(errors==0)
        `uvm_info("SCB",$sformatf("FIFO TEST PASS: checks=%0d",checks),UVM_LOW)
        else
        `uvm_error("SCB",$sformatf("FIFO TEST FAIL: checks=%0d errors=%0d",checks,errors))
    endfunction
endclass
