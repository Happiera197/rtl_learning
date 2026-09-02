class fifo_sequence extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_sequence)
    function new(string name="fifo_sequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat(20)begin
            fifo_item item;
            `uvm_do(item);
        end
    endtask
endclass
