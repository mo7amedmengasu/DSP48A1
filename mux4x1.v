module mux4x1#(
    parameter WIDTH = 18
) (
    input wire [1:0] sel,
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    input wire [WIDTH-1:0] in3,
    input wire [WIDTH-1:0] in4,
    output wire [WIDTH-1:0] out
);
    assign out = (sel == 2'b00) ? in1 :
                 (sel == 2'b01) ? in2 :
                 (sel == 2'b10) ? in3 :
                 in4;
endmodule
// This module implements a 4-to-1 multiplexer with parameterized width