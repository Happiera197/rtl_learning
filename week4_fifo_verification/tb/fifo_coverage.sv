class fifo_coverage;
    typedef enum bit [1:0] {
        OCC_EMPTY,
        OCC_MID,
        OCC_FULL
    } occupancy_e;

    typedef enum bit [1:0] {
        OP_IDLE  = 2'b00,
        OP_READ  = 2'b01,
        OP_WRITE = 2'b10,
        OP_BOTH  = 2'b11
    } operation_e;

    virtual fifo_if vif;
    int unsigned depth;

    /* verilator lint_off VARHIDDEN */
    /* verilator lint_off UNUSEDSIGNAL */
    covergroup fifo_cg with function sample(
        occupancy_e occupancy,
        operation_e operation,
        bit full_write,
        bit empty_read
    );
        cp_occupancy: coverpoint occupancy {
            bins empty = {OCC_EMPTY};
            bins mid   = {OCC_MID};
            bins full  = {OCC_FULL};
        }

        cp_operation: coverpoint operation {
            bins idle  = {OP_IDLE};
            bins write = {OP_WRITE};
            bins read  = {OP_READ};
            bins both  = {OP_BOTH};
        }

        cp_full_write: coverpoint full_write {
            bins hit = {1'b1};
        }

        cp_empty_read: coverpoint empty_read {
            bins hit = {1'b1};
        }

        occupancy_x_operation: cross cp_occupancy, cp_operation;
    endgroup

    covergroup reset_cg with function sample(bit reset_in_flight);
        cp_reset_in_flight: coverpoint reset_in_flight {
            bins hit = {1'b1};
        }
    endgroup
    /* verilator lint_on UNUSEDSIGNAL */
    /* verilator lint_on VARHIDDEN */

    function new(
        virtual fifo_if vif_arg,
        int unsigned depth_arg
    );
        this.vif   = vif_arg;
        this.depth = depth_arg;
        fifo_cg = new();
        reset_cg = new();
    endfunction

    task sample_cycles();
        int unsigned level;
        occupancy_e occupancy;
        operation_e operation;

        forever begin
            @(negedge vif.clk);
            #1step;

            if (vif.resetn) begin
                level = int'(vif.count);

                if (level == 0)
                    occupancy = OCC_EMPTY;
                else if (level >= depth)
                    occupancy = OCC_FULL;
                else
                    occupancy = OCC_MID;

                operation = operation_e'({vif.wren, vif.rden});

                fifo_cg.sample(
                    occupancy,
                    operation,
                    (occupancy == OCC_FULL) && vif.wren,
                    (occupancy == OCC_EMPTY) && vif.rden
                );
            end
        end
    endtask

    task sample_resets();
        bit reset_in_flight;

        forever begin
            wait (vif.resetn);
            @(negedge vif.resetn);

            reset_in_flight =
                (int'(vif.count) != 0) || vif.wren || vif.rden;
            reset_cg.sample(reset_in_flight);
        end
    endtask

    task run();
        fork
            sample_cycles();
            sample_resets();
        join
    endtask
endclass
