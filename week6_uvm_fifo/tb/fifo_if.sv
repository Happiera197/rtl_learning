interface fifo_if #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DATA_DEPTH = 16
)(
    input logic clk
);
    logic resetn;

    logic wren;
    logic rden;

    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;

    logic full;
    logic empty;
    logic [$clog2(DATA_DEPTH+1)-1:0] count;

    property p_count_range;
        @(posedge clk)
        disable iff(!resetn)
        count <= DATA_DEPTH;
    endproperty

    a_count_range:assert property(p_count_range)
    else
        $error(
        "FIFO count exceeds DATA_DEPTH"
        );

    property p_empty_correct;
        @(posedge clk)
        disable iff(!resetn)
        empty == (count == 0);
    endproperty

    a_empty_correct:assert property(p_empty_correct)
    else
        $error(
        "FIFO empty flag is incorrect"
        );

    property p_full_correct;
        @(posedge clk)
        disable iff(!resetn)
        full == (count == DATA_DEPTH);
    endproperty

    a_full_correct:assert property(p_full_correct)
    else
        $error(
        "FIFO full flag is incorrect"
        );

    property p_empty_read_hold;
        @(posedge clk)
        disable iff(!resetn)
        (empty && rden && !wren)|=>(count == $past(count));
    endproperty


    a_empty_read_hold:assert property(p_empty_read_hold)
    else
        $error(
        "Read from empty FIFO changed count"
            );

    property p_full_write_hold;
        @(posedge clk)
        disable iff(!resetn)
        (full && wren && !rden)|=>(count == $past(count));
    endproperty


    a_full_write_hold:assert property(p_full_write_hold)
    else
        $error(
        "Write to full FIFO changed count"
        );

    property p_simultaneous_rw_hold;
        @(posedge clk)
        disable iff(!resetn)
        (wren && rden && !empty)|=>(count == $past(count));
    endproperty


    a_simultaneous_rw_hold:assert property(p_simultaneous_rw_hold)
    else
        $error(
        "Simultaneous read/write changed count"
        );

     c_empty_read:
    cover property(
        @(posedge clk)
        disable iff(!resetn)

        empty && rden
    );


    c_full_write:
    cover property(
        @(posedge clk)
        disable iff(!resetn)

        full && wren
    );


    c_simultaneous_rw:
    cover property(
        @(posedge clk)
        disable iff(!resetn)

        wren && rden
    );

endinterface
