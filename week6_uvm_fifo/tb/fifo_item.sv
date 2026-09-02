class fifo_item extends uvm_sequence_item;
typedef enum{IDLE,READ,WRITE,WRITE_READ,RESET}op_t;
    rand op_t op;
    rand bit [DATA_WIDTH-1:0] data;

    logic resetn;
    logic wren;
    logic rden;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic full;
    logic empty;
    logic [$clog2(DATA_DEPTH+1)-1:0] count;

    constraint op_c{op dist{
        READ:=2,
        WRITE:=2,
        WRITE_READ:=1,
        RESET:=1
    };}
    constraint data_c{data inside {[0:255]};}
    function new(string name="fifo_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(fifo_item)
        `uvm_field_int(data,UVM_ALL_ON)
        `uvm_field_enum(op_t,op,UVM_ALL_ON)
        `uvm_field_int(resetn, UVM_ALL_ON)
        `uvm_field_int(wren,   UVM_ALL_ON)
        `uvm_field_int(rden,   UVM_ALL_ON)
        `uvm_field_int(wdata,  UVM_ALL_ON)
        `uvm_field_int(rdata,  UVM_ALL_ON)
        `uvm_field_int(full,   UVM_ALL_ON)
        `uvm_field_int(empty,  UVM_ALL_ON)
        `uvm_field_int(count,  UVM_ALL_ON)
    `uvm_object_utils_end

endclass
