module and_gate (
    input  logic a,
    input  logic b,
    output logic y
);

    timeunit 1ns;
    timeprecision 1ps;

    assign y = a & b;

endmodule
