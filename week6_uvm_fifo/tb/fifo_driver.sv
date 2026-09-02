class fifo_driver extends uvm_driver #(fifo_item);
    `uvm_component_utils(fifo_driver)
    fifo_vif_t vif;
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(fifo_vif_t)::get(this,"","vif",vif))begin
        `uvm_fatal("NO_VIF","fifo_driver cannot get virtual interface")
    end
endfunction
    virtual task run_phase(uvm_phase phase);
        vif.wren<=0;
        vif.rden<=0;
        vif.resetn<=0;
        vif.wdata<=0;

        repeat(2)@(posedge vif.clk);

        @(negedge vif.clk);
        vif.resetn<=1;
        forever begin
            seq_item_port.get_next_item(req);
                `uvm_info("DRIVER",req.sprint(),UVM_MEDIUM)
                case(req.op)
                    fifo_item::WRITE:begin
                        @(negedge vif.clk);
                        vif.wren  <= 1;
                        vif.rden  <= 0;
                        vif.wdata <= req.data;
                        @(negedge vif.clk);
                        vif.wren <= 0;
                    end

                    fifo_item::READ:begin
                        @(negedge vif.clk);
                        vif.wren <= 0;
                        vif.rden <= 1;
                        @(negedge vif.clk);
                        vif.rden <= 0;
                    end

                    fifo_item::WRITE_READ: begin
                    @(negedge vif.clk);
                    vif.wren  <= 1;
                    vif.rden  <= 1;
                    vif.wdata <= req.data;
                    @(negedge vif.clk);
                    vif.wren <= 0;
                    vif.rden <= 0;
                end

                 fifo_item::RESET: begin
                    @(negedge vif.clk);
                    vif.wren<= 0;
                    vif.rden<= 0;
                    vif.resetn<= 0;
                    repeat(2)@(posedge vif.clk);

                    @(negedge vif.clk);
                    vif.resetn <= 1;
                end

                default: begin
                    @(negedge vif.clk);
                    vif.wren <= 0;
                    vif.rden <= 0;
                end

                endcase
            seq_item_port.item_done();
        end
    endtask
endclass
