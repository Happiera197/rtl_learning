class fifo_coverage extends uvm_subscriber#(fifo_item);
    `uvm_component_utils(fifo_coverage)
    fifo_item tr;
    covergroup fifo_cg;
        option.per_instance = 1;
         cp_op: coverpoint tr.op {

            bins idle =
                {fifo_item::IDLE};

            bins read =
                {fifo_item::READ};

            bins write =
                {fifo_item::WRITE};

            bins write_read =
                {fifo_item::WRITE_READ};

            bins reset =
                {fifo_item::RESET};

        }
        cp_count: coverpoint tr.count {

            bins empty =
                {0};

            bins middle =
                {[1:DATA_DEPTH-1]};

            bins full =
                {DATA_DEPTH};

        }
        cp_empty: coverpoint tr.empty {
            bins not_empty = {0};
            bins empty     = {1};

        }
        cp_full: coverpoint tr.full {
            bins not_full = {0};
            bins full     = {1};
        }
        op_count_cross:
            cross cp_op, cp_count;
    endgroup

    function new(
        string name,
        uvm_component parent
    );
        super.new(name,parent);

        fifo_cg = new();

    endfunction
    virtual function void write(
        fifo_item t
    );

        tr = t;

        fifo_cg.sample();

    endfunction
    virtual function void report_phase(
        uvm_phase phase
    );

        super.report_phase(phase);

        `uvm_info(
            "COV",
            $sformatf(
                "Functional Coverage = %0.2f%%",
                fifo_cg.get_inst_coverage()
            ),
            UVM_LOW
        )

    endfunction

endclass
