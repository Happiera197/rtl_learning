class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction
    fifo_env m_env;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env=fifo_env::type_id::create("m_env",this);

       // uvm_config_db#(uvm_object_wrapper)::set(this,"*m_sequencer.run_phase","default_sequence",fifo_sequence::get_type());
    endfunction
    virtual task run_phase(uvm_phase phase);
        fifo_sequence seq;
        phase.raise_objection(this);
            seq=fifo_sequence::type_id::create("seq");
            seq.start(m_env.m_agent.m_sequencer);
        phase.drop_objection(this);
    endtask
    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_top.print_topology(uvm_default_tree_printer);
    endfunction
endclass
