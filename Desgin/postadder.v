module postadder#(
    parameter WIDTH = 48
) (
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire add_sub, 
    input wire  C_in,
    output wire [WIDTH-1:0] SUM,
    output wire C_out
);

    wire[WIDTH:0] temp_sum;
    assign temp_sum = add_sub ? (A - B - C_in) : (A + B + C_in);
    assign SUM = temp_sum[WIDTH-1:0];
    assign C_out = temp_sum[WIDTH];
endmodule
