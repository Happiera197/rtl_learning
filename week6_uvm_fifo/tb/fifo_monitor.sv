class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)
    uvm_analysis_port#(fifo_item)ap;
    fifo_vif_t vif;
    function new(string name,uvm_component parent);
        super.new(name,parent);
        ap=new("ap",this);
    endfunction
    virtual function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);

        if(!uvm_config_db#(fifo_vif_t)::get(
            this,
            "",
            "vif",
            vif
        ))
        begin
            `uvm_fatal("NO_VIF","fifo_monitor cannot get virtual interface")
        end
    endfunction

virtual task run_phase(uvm_phase phase);
    fifo_item tr;

        forever begin

            @(negedge vif.clk);

            tr = fifo_item::type_id::create("tr");

            tr.resetn = vif.resetn;

            tr.wren = vif.wren;
            tr.rden = vif.rden;

            tr.wdata = vif.wdata;
            tr.rdata = vif.rdata;

            tr.full  = vif.full;
            tr.empty = vif.empty;
            tr.count = vif.count;


            if(!vif.resetn)
                tr.op = fifo_item::RESET;

            else begin

                case({vif.wren, vif.rden})

                    2'b10:
                        tr.op = fifo_item::WRITE;

                    2'b01:
                        tr.op = fifo_item::READ;

                    2'b11:
                        tr.op = fifo_item::WRITE_READ;

                    default:
                        tr.op = fifo_item::IDLE;

                endcase

            end


            ap.write(tr);

        end
        endtask
endclass
