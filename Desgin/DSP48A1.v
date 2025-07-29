module DSP48A1#(
    // Pipeline register configuration for A and B input paths
    parameter A0REG       = 0,  // First pipeline register for A
    parameter A1REG       = 1,  // Second pipeline register for A
    parameter B0REG       = 0,  // First pipeline register for B
    parameter B1REG       = 1,  // Second pipeline register for B

    // Register configuration for internal paths
    parameter CREG        = 1,  // Register for C input (used in post-adder)
    parameter DREG        = 1,  // Register for D input (used in pre-adder)
    parameter MREG        = 1,  // Register for multiplier output
    parameter PREG        = 1,  // Register for P output (post-adder output)
    parameter OPMODEREG   = 1,  // Register for OPMODE control signal
    parameter CARRYINREG  = 1,  // Register for carry-in
    parameter CARRYOUTREG = 1,  // Register for carry-out
    parameter OPMODREG    = 1,  // [Duplicate, possibly same as OPMODEREG?]

    // Control for selecting carry input source
    parameter CARRYINSEL  = "OPMODE5", // Use "CARRYIN" or "OPMODE5"

    // Determines if B input is taken directly or from BCIN
    parameter B_INPUT     = "DIRECT",   // "DIRECT" or "CASCADE"

    // Type of reset: SYNC or ASYNC
    parameter RSTTYPE     = "SYNC"
)(
    // ------------- Data Ports -------------

    // 18-bit inputs for multiplier and adder paths
    input  [17:0] A,     // Multiplier input (can also go to adder)
    input  [17:0] B,     // Multiplier input or pre-adder input
    input  [17:0] BCIN,     // Input for pre-adder (combined with A or B)
    input  [47:0] C,     // 48-bit input for post-adder
    input  [17:0] D,     // Input for pre-adder (combined with A or B)

    // Carry input for post-adder
    input  CARRYIN,

    // Outputs
    output [35:0] M,     // Multiplier output (buffered)
    output [47:0] P,     // Main output from post-adder (accumulated value)
    output CARRYOUT,     // Cascade carry out (to adjacent slice)
    output CARRYOUTF,    // Carry out to general FPGA logic

    // ------------- Control Input Ports -------------

    input  [7:0] OPMODE, // Selects operation mode (e.g., multiply, add, etc.)
    input  CLK,          // Single clock for all pipeline stages

    // ------------- Clock Enable Input Ports -------------

    input  CEA,          // Enable for A pipeline registers
    input  CEB,          // Enable for B pipeline registers
    input  CEC,          // Enable for C register
    input  CECARRYIN,    // Enable for carry-in and carry-out registers
    input  CED,          // Enable for D register
    input  CEM,          // Enable for M (multiplier) register
    input  CEOPMODE,     // Enable for OPMODE register
    input  CEP,          // Enable for P output register

    // ------------- Reset Input Ports -------------

    // All resets are active-high. Type is defined by RSTTYPE parameter.
    input  RSTA,         // Reset for A pipeline registers
    input  RSTB,         // Reset for B pipeline registers
    input  RSTC,         // Reset for C register
    input  RSTCARRYIN,   // Reset for carry-in/out registers
    input  RSTD,         // Reset for D register
    input  RSTM,         // Reset for M register
    input  RSTOPMODE,    // Reset for OPMODE register
    input  RSTP,         // Reset for P register

    // ------------- Cascade Ports -------------

    output [17:0] BCOUT,   // Cascade input for B (from previous DSP slice)
    input  [47:0] PCIN,   // Cascade input for P (from previous DSP slice)
    output [47:0] PCOUT   // Cascade output for P (to next DSP slice)
    // ----------------------------------------
);

    // Internal signals
    wire [17:0] A0_out, A1_out, B0_out, B1_out;
    wire [17:0] B_mux_out, D_reg_out;
    wire [17:0] preadder_out;
    wire [35:0] multiplier_out, M_reg_out;
    wire [47:0] C_reg_out, X_mux_out, Z_mux_out;
    wire [47:0] postadder_out, P_reg_out;
    wire [7:0] OPMODE_reg_out;
    wire carryin_reg_out, carryout_wire;

    // A input pipeline (A0REG -> A1REG)
    pipe_stage #(.N(18), .RSTTYPE(RSTTYPE)) A0_stage (
        .clk(CLK), .rst(RSTA), .sel(A0REG), .clken(CEA),
        .d(A), .q(A0_out)
    );
    
    pipe_stage #(.N(18), .RSTTYPE(RSTTYPE)) A1_stage (
        .clk(CLK), .rst(RSTA), .sel(A1REG), .clken(CEA),
        .d(A0_out), .q(A1_out)
    );

    // B input selection and pipeline (B0REG -> B1REG)
    mux2x1 #(.WIDTH(18)) B_input_mux (
        .sel(B_INPUT == "CASCADE"),
        .in1(B), .in2(BCIN),
        .out(B_mux_out)
    );
    
    pipe_stage #(.N(18), .RSTTYPE(RSTTYPE)) B0_stage (
        .clk(CLK), .rst(RSTB), .sel(B0REG), .clken(CEB),
        .d(B_mux_out), .q(B0_out)
    );
    
    // D input register
    pipe_stage #(.N(18), .RSTTYPE(RSTTYPE)) D_stage (
        .clk(CLK), .rst(RSTD), .sel(DREG), .clken(CED),
        .d(D), .q(D_reg_out)
    );

    // Pre-adder (D +/- A or D +/- B based on OPMODE[4])
    // Uses A1 output and B0 output (before B1 register)

    
    preadder #(.WIDTH(18)) pre_add (
        .A(D_reg_out),
        .B(B0_out),
        .add_sub(OPMODE_reg_out[6]), // OPMODE[6] controls add/subtract  
        .SUM(preadder_out)
    );

    // B1 stage - can receive either B0_out or preadder_out based on OPMODE[4]
    wire [17:0] B1_input;
    assign B1_input = OPMODE_reg_out[4] ? preadder_out : B0_out;
    
    pipe_stage #(.N(18), .RSTTYPE(RSTTYPE)) B1_stage (
        .clk(CLK), .rst(RSTB), .sel(B1REG), .clken(CEB),
        .d(B1_input), .q(B1_out)
    );

    // C input register
    pipe_stage #(.N(48), .RSTTYPE(RSTTYPE)) C_stage (
        .clk(CLK), .rst(RSTC), .sel(CREG), .clken(CEC),
        .d(C), .q(C_reg_out)
    );

    // Multiplier (A1 * B1)
    // B1 now contains either B0_out or preadder_out based on OPMODE[5]
    assign multiplier_out = A1_out * B1_out;

    // M register (multiplier output register)
    pipe_stage #(.N(36), .RSTTYPE(RSTTYPE)) M_stage (
        .clk(CLK), .rst(RSTM), .sel(MREG), .clken(CEM),
        .d(multiplier_out), .q(M_reg_out)
    );
    //----------------------------------------------------------------------------------------------//

    // OPMODE register
    pipe_stage #(.N(8), .RSTTYPE(RSTTYPE)) OPMODE_stage (
        .clk(CLK), .rst(RSTOPMODE), .sel(OPMODEREG), .clken(CEOPMODE),
        .d(OPMODE), .q(OPMODE_reg_out)
    );

    // Carry-in register and selection
    wire carryin_selected;
    assign carryin_selected = (CARRYINSEL == "CARRYIN") ? CARRYIN : OPMODE_reg_out[5];
    
    pipe_stage #(.N(1), .RSTTYPE(RSTTYPE)) CARRYIN_stage (
        .clk(CLK), .rst(RSTCARRYIN), .sel(CARRYINREG), .clken(CECARRYIN),
        .d(carryin_selected), .q(carryin_reg_out)
    );

    // Post-adder input multiplexers
    // X multiplexer (OPMODE[1:0])
    mux4x1 #(.WIDTH(48)) X_mux (
        .sel(OPMODE_reg_out[1:0]),
        .in1(48'b0),                    // 00: Zero
        .in2({{12{M_reg_out[35]}}, M_reg_out}), // 01: M (sign-extended)
        .in3(P_reg_out),                // 10: P
        .in4({D_reg_out[11:0], A1_out, B1_out}), // 11: Concatenated D:A:B
        .out(X_mux_out)
    );

    // Z multiplexer (OPMODE[3:2] for Z selection)
    mux4x1 #(.WIDTH(48)) Z_mux (
        .sel(OPMODE_reg_out[3:2]),
        .in1(48'b0),                    // 00: Zero
        .in2(PCIN),                     // 01: PCIN  
        .in3(P_reg_out),                // 10: P
        .in4(C_reg_out),                // 11: C
        .out(Z_mux_out)
    );

    // Post-adder: Z ± X (no separate Y multiplexer)
    postadder #(.WIDTH(48)) post_add (
        .A(Z_mux_out),
        .B(X_mux_out),                  // Just X, no Y
        .add_sub(OPMODE_reg_out[7]),    // OPMODE[7] controls add/subtract
        .C_in(carryin_reg_out),
        .SUM(postadder_out),
        .C_out(carryout_wire)
    );

    // P output register
    pipe_stage #(.N(48), .RSTTYPE(RSTTYPE)) P_stage (
        .clk(CLK), .rst(RSTP), .sel(PREG), .clken(CEP),
        .d(postadder_out), .q(P_reg_out)
    );

    // Carry-out register
    pipe_stage #(.N(1), .RSTTYPE(RSTTYPE)) CARRYOUT_stage (
        .clk(CLK), .rst(RSTCARRYIN), .sel(CARRYOUTREG), .clken(CECARRYIN),
        .d(carryout_wire), .q(CARRYOUT)
    );

    // Output assignments
    assign M = M_reg_out;
    assign P = P_reg_out;
    assign CARRYOUTF = carryout_wire; // Direct carry-out to fabric
    assign PCOUT = P_reg_out;         // Cascade output
    assign BCOUT = B1_out;            // Cascade output for B (from B1 stage)

endmodule
