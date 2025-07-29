module preadder#(
    parameter WIDTH = 18
) (
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire add_sub, // 0 for addition, 1 for subtraction    
    output wire [WIDTH-1:0] SUM
);
    assign SUM = add_sub ? (A - B) : (A + B);
endmodule
