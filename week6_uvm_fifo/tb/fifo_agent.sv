class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction
    fifo_driver m_driver;
    fifo_monitor m_monitor;
    fifo_sequencer m_sequencer;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(is_active==UVM_ACTIVE)begin
            m_driver=fifo_driver::type_id::create("m_driver",this);
            m_sequencer=fifo_sequencer::type_id::create("m_sequencer",this);
        end
            m_monitor=fifo_monitor::type_id::create("m_monitor",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(is_active==UVM_ACTIVE)begin
            m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        end
    endfunction

endclass
