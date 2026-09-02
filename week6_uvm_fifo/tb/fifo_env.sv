class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction
    fifo_agent m_agent;
    fifo_scoreboard m_scoreboard;
    fifo_coverage m_coverage;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_agent=fifo_agent::type_id::create("m_agent",this);
        m_scoreboard=fifo_scoreboard::type_id::create("m_scoreboard",this);
        m_coverage=fifo_coverage::type_id::create("m_coverage",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_agent.m_monitor.ap.connect(m_scoreboard.ap);
        m_agent.m_monitor.ap.connect(m_coverage.analysis_export);
    endfunction
endclass
