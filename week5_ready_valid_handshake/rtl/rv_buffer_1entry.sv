module rv_buffer_1entry #(
    parameter int WIDTH = 8
)(
    input  logic             clk,
    input  logic             resetn,

    input  logic             s_valid,
    output logic             s_ready,
    input  logic [WIDTH-1:0] s_data,

    output logic             m_valid,
    input  logic             m_ready,
    output logic [WIDTH-1:0] m_data
);

    assign s_ready = !m_valid || m_ready;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            m_valid <= 1'b0;
            m_data  <= '0;
        end else if (s_ready) begin
            m_valid <= s_valid;

            if (s_valid) begin
                m_data <= s_data;
            end
        end
    end

endmodule
