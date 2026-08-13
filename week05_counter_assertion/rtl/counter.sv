`timescale 1ns/1ps

module counter (
    input  logic       clk,
    input  logic       resetn,
    input  logic       enable,
    output logic [3:0] count
);

    always_ff @(posedge clk) begin
        if (!resetn) begin
            count <= 4'd0;
        end else if (enable) begin
            if (count == 4'd15)
                count <= 4'd0;
            else
                count <= count + 4'd1;
        end else begin
            count <= count;
        end
    end

endmodule
