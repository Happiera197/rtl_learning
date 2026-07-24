module ALU #(
    parameter int unsigned WIDTH = 8
) (
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [3:0]       op,

    output logic [WIDTH-1:0] result,
    output logic             zero,
    output logic             carry,
    output logic             overflow
);
localparam logic [3:0] OP_ADD  = 4'h0;
localparam logic [3:0] OP_SUB  = 4'h1;
localparam logic [3:0] OP_AND  = 4'h2;
localparam logic [3:0] OP_OR   = 4'h3;
localparam logic [3:0] OP_XOR  = 4'h4;
localparam logic [3:0] OP_SLT  = 4'h5;
localparam logic [3:0] OP_SLTU = 4'h6;
localparam logic [3:0] OP_SHL  = 4'h7;
localparam logic [3:0] OP_SHR  = 4'h8;

logic [WIDTH:0] EX_result;

 timeunit 1ns;
    timeprecision 1ps;

always_comb begin
    carry           = 1'b0;
    overflow        = 1'b0;
    EX_result = '0;
    case(op)
    OP_ADD:begin
        EX_result={1'b0,a}+{1'b0,b};
        result=EX_result[WIDTH-1:0];
        carry=EX_result[WIDTH];
        overflow=(~(a[WIDTH-1]^b[WIDTH-1]))&(result[WIDTH-1]^a[WIDTH-1]);
    end
    OP_SUB:begin
 EX_result={1'b0,a}+{1'b0,~b}+1'b1;
        result=EX_result[WIDTH-1:0];
        carry=EX_result[WIDTH];
        overflow=(a[WIDTH-1]^b[WIDTH-1])&(result[WIDTH-1]^a[WIDTH-1]);
    end
    OP_AND:result=a&b;
    OP_OR:result=a|b;
    OP_XOR:result=a^b;
    OP_SLT:result={{(WIDTH-1){1'b0}},($signed(a)<$signed(b))};
    OP_SLTU:result={{(WIDTH-1){1'b0}},(a<b)};
    OP_SHL:result = a << 1;
    OP_SHR:result = a >> 1;
    default:result={WIDTH{1'b0}};
    endcase
end
assign zero=(result=='0);
endmodule
