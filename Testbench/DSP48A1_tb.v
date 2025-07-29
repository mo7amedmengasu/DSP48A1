`timescale 1ns / 1ps

module DSP48A1_tb;

    // Parameters matching the specification
    parameter A0REG       = 0;
    parameter A1REG       = 1;
    parameter B0REG       = 0;
    parameter B1REG       = 1;
    parameter CREG        = 1;
    parameter DREG        = 1;
    parameter MREG        = 1;
    parameter PREG        = 1;
    parameter CARRYINREG  = 1;
    parameter CARRYOUTREG = 1;
    parameter OPMODEREG   = 1;
    parameter CARRYINSEL  = "OPMODE5";
    parameter B_INPUT     = "DIRECT";
    parameter RSTTYPE     = "SYNC";

    // Testbench signals
    reg [17:0] A, B, BCIN, D;
    reg [47:0] C, PCIN;
    reg CARRYIN;
    reg [7:0] OPMODE;
    reg CLK;
    reg CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP;
    reg RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP;

    // Output wires
    wire [35:0] M;
    wire [47:0] P;
    wire CARRYOUT, CARRYOUTF;
    wire [17:0] BCOUT;
    wire [47:0] PCOUT;

    // DUT instantiation
    DSP48A1 #(
        .A0REG(A0REG), .A1REG(A1REG), .B0REG(B0REG), .B1REG(B1REG),
        .CREG(CREG), .DREG(DREG), .MREG(MREG), .PREG(PREG),
        .CARRYINREG(CARRYINREG), .CARRYOUTREG(CARRYOUTREG), .OPMODEREG(OPMODEREG),
        .CARRYINSEL(CARRYINSEL), .B_INPUT(B_INPUT), .RSTTYPE(RSTTYPE)
    ) dut (
        .A(A), .B(B), .BCIN(BCIN), .C(C), .D(D), .CARRYIN(CARRYIN),
        .M(M), .P(P), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF),
        .OPMODE(OPMODE), .CLK(CLK),
        .CEA(CEA), .CEB(CEB), .CEC(CEC), .CECARRYIN(CECARRYIN),
        .CED(CED), .CEM(CEM), .CEOPMODE(CEOPMODE), .CEP(CEP),
        .RSTA(RSTA), .RSTB(RSTB), .RSTC(RSTC), .RSTCARRYIN(RSTCARRYIN),
        .RSTD(RSTD), .RSTM(RSTM), .RSTOPMODE(RSTOPMODE), .RSTP(RSTP),
        .BCOUT(BCOUT), .PCIN(PCIN), .PCOUT(PCOUT)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns period
    end

    // Initialize all signals
    initial begin
        // Set all enables to 1
        CEA = 1; CEB = 1; CEC = 1; CECARRYIN = 1;
        CED = 1; CEM = 1; CEOPMODE = 1; CEP = 1;
        
        // Set all resets to 0
        RSTA = 0; RSTB = 0; RSTC = 0; RSTCARRYIN = 0;
        RSTD = 0; RSTM = 0; RSTOPMODE = 0; RSTP = 0;
        
        // Initialize inputs
        A = 0; B = 0; BCIN = 0; C = 0; D = 0; PCIN = 0; CARRYIN = 0; OPMODE = 0;
    end

    // Main test sequence
    initial begin
        $display("Starting DSP48A1 Simple Testbench");
        $display("=================================");

        // Wait for clock to start
        repeat(2) @(negedge CLK);

        //=================================================================
        // Test 1: Reset Operation
        //=================================================================
        $display("\nTest 1: Reset Operation");
        
        // Apply resets
        RSTA = 1; RSTB = 1; RSTC = 1; RSTCARRYIN = 1;
        RSTD = 1; RSTM = 1; RSTOPMODE = 1; RSTP = 1;
        
        // Apply some inputs
        A = 100; B = 200; C = 300; D = 400;
        
        @(negedge CLK);
        
        // Check outputs are zero
        if (M == 0 && P == 0 && PCOUT == 0 && BCOUT == 0 && CARRYOUT == 0 && CARRYOUTF == 0)
            $display("PASS: All outputs are zero during reset");
        else
            $display("FAIL: Outputs not zero during reset");
        
        // Remove resets
        RSTA = 0; RSTB = 0; RSTC = 0; RSTCARRYIN = 0;
        RSTD = 0; RSTM = 0; RSTOPMODE = 0; RSTP = 0;

        //=================================================================
        // Test 2: DSP Path 1 (Pre-subtractor + Post-subtractor)
        //=================================================================
        $display("\nTest 2: DSP Path 1");
        
        A = 20; B = 10; C = 350; D = 25;
        OPMODE = 8'b11011101;
        BCIN = 555; PCIN = 777; CARRYIN = 0;
        
        repeat(4) @(negedge CLK);
        
        $display("Inputs: A=%d, B=%d, C=%d, D=%d", A, B, C, D);
        $display("Outputs: BCOUT=%h, M=%h, P=%h", BCOUT, M, P);
        
        if (BCOUT == 18'hf && M == 36'h12c && P == 48'h32)
            $display("PASS: Expected BCOUT=0xF, M=0x12C, P=0x32");
        else
            $display("FAIL: Expected BCOUT=0xF, M=0x12C, P=0x32");

        //=================================================================
        // Test 3: DSP Path 2 (Pre-addition + zeros)
        //=================================================================
        $display("\nTest 3: DSP Path 2");
        
        A = 20; B = 10; C = 350; D = 25;
        OPMODE = 8'b00010000;
        BCIN = 333; PCIN = 444; CARRYIN = 1;
        
        repeat(3) @(negedge CLK);
        
        $display("Inputs: A=%d, B=%d, C=%d, D=%d", A, B, C, D);
        $display("Outputs: BCOUT=%h, M=%h, P=%h", BCOUT, M, P);
        
        if (BCOUT == 18'h23 && M == 36'h2bc && P == 48'h0)
            $display("PASS: Expected BCOUT=0x23, M=0x2BC, P=0x0");
        else
            $display("FAIL: Expected BCOUT=0x23, M=0x2BC, P=0x0");

        //=================================================================
        // Test 4: DSP Path 3 (No pre-adder + P feedback)
        //=================================================================
        $display("\nTest 4: DSP Path 3");
        
        A = 20; B = 10; C = 350; D = 25;
        OPMODE = 8'b00001010;
        BCIN = 111; PCIN = 222; CARRYIN = 0;
        
        repeat(3) @(negedge CLK);
        
        $display("Inputs: A=%d, B=%d, C=%d, D=%d", A, B, C, D);
        $display("Outputs: BCOUT=%h, M=%h, P=%h", BCOUT, M, P);
        
        if (BCOUT == 18'ha && M == 36'hc8)
            $display("PASS: Expected BCOUT=0xA, M=0xC8");
        else
            $display("FAIL: Expected BCOUT=0xA, M=0xC8");

        //=================================================================
        // Test 5: DSP Path 4 (D:A:B Concatenation + PCIN)
        //=================================================================
        $display("\nTest 5: DSP Path 4");
        
        A = 5; B = 6; C = 350; D = 25; PCIN = 3000;
        OPMODE = 8'b10100111;
        BCIN = 999; CARRYIN = 1;
        
        repeat(3) @(negedge CLK);
        
        $display("Inputs: A=%d, B=%d, C=%d, D=%d, PCIN=%d", A, B, C, D, PCIN);
        $display("Outputs: BCOUT=%h, M=%h, P=%h, CARRYOUT=%b", BCOUT, M, P, CARRYOUT);
        
        if (BCOUT == 18'h6 && M == 36'h1e && P == 48'hfe6fffec0bb1 && CARRYOUT == 1)
            $display("PASS: Expected BCOUT=0x6, M=0x1E, P=0xFE6FFFEC0BB1, CARRYOUT=1");
        else
            $display("FAIL: Expected BCOUT=0x6, M=0x1E, P=0xFE6FFFEC0BB1, CARRYOUT=1");

        //=================================================================
        // Test Complete
        //=================================================================
        repeat(5) @(negedge CLK);
        
        $display("\n=================================");
        $display("Testbench Complete");
        $display("=================================");
        $finish;
    end

    // Timeout
    initial begin
        #5000;
        $display("Timeout!");
        $finish;
    end

endmodule
