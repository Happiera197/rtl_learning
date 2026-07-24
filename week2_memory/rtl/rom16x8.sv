`timescale 1ns/1ps
module rom16x8 (
input logic [3:0]addr,
output logic [7:0]rdata
);
logic [7:0]mem [0:15];
initial begin

        mem[0]  = 8'h10;
        mem[1]  = 8'h21;
        mem[2]  = 8'h32;
        mem[3]  = 8'h43;
        mem[4]  = 8'h54;
        mem[5]  = 8'h65;
        mem[6]  = 8'h76;
        mem[7]  = 8'h87;
        mem[8]  = 8'h98;
        mem[9]  = 8'hA9;
        mem[10] = 8'hBA;
        mem[11] = 8'hCB;
        mem[12] = 8'hDC;
        mem[13] = 8'hED;
        mem[14] = 8'hFE;
        mem[15] = 8'h0F;


end

assign rdata=mem[addr];
endmodule
