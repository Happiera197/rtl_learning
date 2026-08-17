module rv_assertions #(
    parameter int WIDTH = 8
)(
    input logic             clk,
    input logic             resetn,
    input logic             s_valid,
    input logic             s_ready,
    input logic [WIDTH-1:0] s_data,
    input logic             m_valid,
    input logic             m_ready,
    input logic [WIDTH-1:0] m_data
);

    property p_valid_hold;
        @(posedge clk)
        disable iff (!resetn)
        m_valid && !m_ready |=> m_valid;
    endproperty

    a_valid_hold:
        assert property (p_valid_hold)
        else $error("m_valid dropped during backpressure");

    property p_data_stable;
        @(posedge clk)
        disable iff (!resetn)
        m_valid && !m_ready |=> $stable(m_data);
    endproperty

    a_data_stable:
        assert property (p_data_stable)
        else $error("m_data changed during backpressure");

    property p_reset_clears_valid;
        @(posedge clk)
        !resetn |-> !m_valid;
    endproperty

    a_reset_clears_valid:
        assert property (p_reset_clears_valid)
        else $error("m_valid was not cleared by reset");

    // These properties check the Source/Testbench protocol behavior.
    property p_s_valid_hold;
        @(posedge clk)
        disable iff (!resetn)
        s_valid && !s_ready |=> s_valid;
    endproperty

    a_s_valid_hold:
        assert property (p_s_valid_hold)
        else $error("Source dropped s_valid before a handshake");

    property p_s_data_stable;
        @(posedge clk)
        disable iff (!resetn)
        s_valid && !s_ready |=> $stable(s_data);
    endproperty

    a_s_data_stable:
        assert property (p_s_data_stable)
        else $error("Source changed s_data before a handshake");

    c_input_handshake:
        cover property (@(posedge clk)
                        resetn && s_valid && s_ready);

    c_output_handshake:
        cover property (@(posedge clk)
                        resetn && m_valid && m_ready);

    c_backpressure:
        cover property (@(posedge clk)
                        resetn && m_valid && !m_ready);

    c_stall_then_transfer:
        cover property (@(posedge clk)
                        resetn && m_valid && !m_ready
                        |=> resetn && m_valid && m_ready);

    c_continuous_transfer:
        cover property (@(posedge clk)
                        resetn && m_valid && m_ready
                        |=> resetn && m_valid && m_ready);

endmodule
