module mux2x1#(
    parameter WIDTH = 18
) (
    input wire sel,
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out
);
    assign out = sel ? in2 : in1;
endmodule
