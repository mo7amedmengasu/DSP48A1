module pipe_stage#(
    parameter N = 18,
    parameter RSTTYPE = "ASYNC"
)(
    input wire clk,
    input wire rst,
    input wire sel, clken,
    input wire [N-1:0] d,
    output wire [N-1:0] q
);

    reg [N-1:0] q_reg;
    
    // The register logic - only updates when sel=1 (pipeline enabled)
    generate
        if (RSTTYPE == "ASYNC") begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    q_reg <= 0;
                end else begin
                    if (clken && sel) begin
                        q_reg <= d;  // Register input when pipeline is enabled
                    end
                end
            end
        end else begin // Synchronous reset
            always @(posedge clk) begin
                if (rst) begin
                    q_reg <= 0;
                end else begin
                    if (clken && sel) begin
                        q_reg <= d;  // Register input when pipeline is enabled
                    end
                end
            end
        end
    endgenerate
    
    // Output mux: sel=1 uses registered value, sel=0 bypasses (direct input)
    assign q = sel ? q_reg : d;

endmodule
