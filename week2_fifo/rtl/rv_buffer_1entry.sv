`timescale 1ns/1ps
module rv_buffer_1entry#(
    parameter int unsigned DATA_WIDTH=8
)(
    input logic clk,
    input logic resetn,

    input logic i_valid,
    output logic o_ready,
    input logic [DATA_WIDTH-1:0]i_data,

    output logic o_valid,
    input logic i_ready,
    output logic [DATA_WIDTH-1:0]o_data

);
logic input_fire;
logic output_fire;

assign input_fire=i_valid&&o_ready;
assign output_fire=o_valid&&i_ready;

assign o_ready=!o_valid||i_ready;

always_ff @(posedge clk,negedge resetn)begin
if(!resetn)begin
    o_valid<=1'b0;
    o_data<='0;
end
else begin
    case({input_fire,output_fire})
    2'b10:begin
        o_valid<=1'b1;
        o_data<=i_data;
    end
    2'b01:o_valid<=1'b0;
    2'b11:begin
        o_valid<=1'b1;
        o_data<=i_data;
    end
    default:begin
        o_valid<=o_valid;
        o_data<=o_data;
    end
    endcase
end
end

endmodule
