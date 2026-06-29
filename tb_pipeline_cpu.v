`timescale 1ns/1ps

module tb_pipeline_cpu;

    reg clk;
    reg reset;

    localparam OP_MOV = 5'd0;
    localparam OP_CMP = 5'd1;
    localparam OP_ADD = 5'd2;
    localparam OP_LDI = 5'd4;
    localparam OP_LDS = 5'd5;
    localparam OP_STS = 5'd6;
    localparam OP_BGT = 5'd10;
    localparam OP_INC = 5'd12;
    localparam OP_JMP = 5'd7;

    pipeline_cpu CPU (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("pipeline_tb.vcd");
        $dumpvars(0, tb_pipeline_cpu);

        clk = 0;
        reset = 1;

        for (i = 0; i < 256; i = i + 1)
            CPU.IMEM.imem[i] = 16'd0;

        // R1 = 2
        CPU.IMEM.imem[0] = {OP_LDI, 3'd1, 3'd0, 5'd0};
        CPU.IMEM.imem[1] = 16'd2;

        // R2 = 3
        CPU.IMEM.imem[2] = {OP_LDI, 3'd2, 3'd0, 5'd0};
        CPU.IMEM.imem[3] = 16'd3;

        // R1 = 5
        CPU.IMEM.imem[4] = {OP_ADD, 3'd1, 3'd2, 5'd0};

        // MOV R3, R1 => R3 = 5
        CPU.IMEM.imem[5] = {OP_MOV, 3'd3, 3'd1, 5'd0};

        // INC R3 => R3 = 6
        CPU.IMEM.imem[6] = {OP_INC, 3'd3, 3'd0, 5'd0};

        // R7 = 4
        CPU.IMEM.imem[7] = {OP_LDI, 3'd7, 3'd0, 5'd0};
        CPU.IMEM.imem[8] = 16'd4;

        // STS R7, 20 => RAM[20] = 4
        CPU.IMEM.imem[9] = {OP_STS, 3'd7, 3'd0, 5'd0};
        CPU.IMEM.imem[10] = 16'd20;

        // CMP R3, R2 => 6 - 3 > 0
        CPU.IMEM.imem[11] = {OP_CMP, 3'd3, 3'd2, 5'd0};

        // BGT 18
        CPU.IMEM.imem[12] = {OP_BGT, 3'd0, 3'd0, 5'd0};
        CPU.IMEM.imem[13] = 16'd18;

        // should be skipped
        CPU.IMEM.imem[14] = {OP_LDI, 3'd4, 3'd0, 5'd0};
        CPU.IMEM.imem[15] = 16'd8;

        CPU.IMEM.imem[16] = {OP_LDI, 3'd4, 3'd0, 5'd0};
        CPU.IMEM.imem[17] = 16'd8;

        // branch target
        // R4 = 7
        CPU.IMEM.imem[18] = {OP_LDI, 3'd4, 3'd0, 5'd0};
        CPU.IMEM.imem[19] = 16'd7;

        // LDS R5, 20
        // R5 = RAM[20] = 4
        CPU.IMEM.imem[20] = {OP_LDS, 3'd5, 3'd0, 5'd0};
        CPU.IMEM.imem[21] = 16'd20;

        // dependent instruction: load-use stall required
        // R6 = R6 + R5 = 0 + 4 = 4
        CPU.IMEM.imem[22] = {OP_ADD, 3'd6, 3'd5, 5'd0};

        CPU.IMEM.imem[23] = {OP_JMP, 3'd6, 3'd5, 5'd0};
        CPU.IMEM.imem[24] = 16'd23;

        #10 reset = 0;

        #800;

        $display("R1 = %d", CPU.RF.regs[1]); // 5
        $display("R2 = %d", CPU.RF.regs[2]); // 3
        $display("R3 = %d", CPU.RF.regs[3]); // 6
        $display("R4 = %d", CPU.RF.regs[4]); // 7
        $display("R5 = %d", CPU.RF.regs[5]); // 4
        $display("R6 = %d", CPU.RF.regs[6]); // 4
        $display("R7 = %d", CPU.RF.regs[7]); // 4
        $display("RAM[20] = %d", CPU.RAM.ram[20]); // 4

        $finish;
    end

endmodule