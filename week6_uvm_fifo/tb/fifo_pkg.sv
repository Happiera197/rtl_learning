package fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    parameter int DATA_WIDTH = 8;
    parameter int DATA_DEPTH = 16;

    typedef virtual fifo_if #(
        DATA_WIDTH,
        DATA_DEPTH
    ) fifo_vif_t;
    `include "fifo_item.sv"
    `include "fifo_sequence.sv"
    `include "fifo_sequencer.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"
    `include "fifo_agent.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_coverage.sv"
    `include "fifo_env.sv"
    `include "fifo_test.sv"
endpackage
