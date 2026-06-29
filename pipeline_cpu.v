// Instruction format

// First word:
// [15:11] opcode
// [10:8]  rd
// [7:5]   rs
// [4:0]   unused
//
// Two-word instructions use the next memory word as imm16/address16.
//
// Opcode table:
// 0 : MOV rd, rs          rd = rs
// 1 : CMP rd, rs          updates flags using rd - rs, no register write
// 2 : ADD rd, rs          rd = rd + rs
// 3 : SUB rd, rs          rd = rd - rs
// 4 : LDI rd, imm16       two-word
// 5 : LDS rd, addr16      two-word
// 6 : STS rd, addr16      two-word, stores rd into RAM[addr16]
// 7 : JMP addr16          two-word
// 8 : BEQ addr16          two-word
// 9 : BNE addr16          two-word
// 10: BGT addr16          two-word
// 11: BLT addr16          two-word
// 12: INC rd              rd = rd + 1
// 13: DEC rd              rd = rd - 1
// 14: NEG rd              rd = -rd
// 15: AND rd, rs          rd = rd & rs
// 16: OR  rd, rs          rd = rd | rs

`define OP_MOV 5'd0
`define OP_CMP 5'd1
`define OP_ADD 5'd2
`define OP_SUB 5'd3
`define OP_LDI 5'd4
`define OP_LDS 5'd5
`define OP_STS 5'd6
`define OP_JMP 5'd7
`define OP_BEQ 5'd8
`define OP_BNE 5'd9
`define OP_BGT 5'd10
`define OP_BLT 5'd11
`define OP_INC 5'd12
`define OP_DEC 5'd13
`define OP_NEG 5'd14
`define OP_AND 5'd15
`define OP_OR  5'd16

// Instruction memory
module instruction_memory(
    input  [15:0] addr,
    output [15:0] instr
);
    reg [15:0] imem [0:255];
    assign instr = imem[addr[7:0]];
endmodule

// Data RAM
module data_ram(
    input clk,
    input mem_read,
    input mem_write,
    input [15:0] addr,
    input [15:0] write_data,
    output [15:0] read_data
);
    reg [15:0] ram [0:255];

    assign read_data = mem_read ? ram[addr[7:0]] : 16'd0;

    always @(posedge clk) begin
        if (mem_write)
            ram[addr[7:0]] <= write_data;
    end
endmodule

// Register file
module register_file(
    input clk,
    input reset,
    input reg_write,
    input [2:0] read_addr1,
    input [2:0] read_addr2,
    input [2:0] write_addr,
    input [15:0] write_data,
    output [15:0] read_data1,
    output [15:0] read_data2
    // output [3:0] r0,
    // output [3:0] r1,
    // output [3:0] r2,
    // output [3:0] r3,
    // output [3:0] r4,
    // output [3:0] r5,
    // output [3:0] r6,
    // output [3:0] r7 
);
    reg [15:0] regs [0:7];

    // Debug wires for GTKWave
    wire [15:0] r0 = regs[0];
    wire [15:0] r1 = regs[1];
    wire [15:0] r2 = regs[2];
    wire [15:0] r3 = regs[3];
    wire [15:0] r4 = regs[4];
    wire [15:0] r5 = regs[5];
    wire [15:0] r6 = regs[6];
    wire [15:0] r7 = regs[7];

    // assign r1 = regs[0][3:0];
    // assign r2 = regs[2][3:0];
    // assign r3 = regs[3][3:0];
    // assign r4 = regs[4][3:0];
    // assign r5 = regs[5][3:0];
    // assign r6 = regs[6][3:0];
    // assign r7 = regs[7][3:0];

    integer i;

    assign read_data1 =
        (reg_write && (write_addr == read_addr1)) ? write_data : regs[read_addr1];

    assign read_data2 =
        (reg_write && (write_addr == read_addr2)) ? write_data : regs[read_addr2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 16'd0;
        end else if (reg_write) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule

// Control unit
module control_unit(
    input [4:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg is_two_word,
    output reg uses_rd_as_source,
    output reg uses_rs_as_source
);
    always @(*) begin
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        is_two_word = 0;
        uses_rd_as_source = 0;
        uses_rs_as_source = 0;

        case (opcode)
            `OP_MOV: begin
                reg_write = 1;
                uses_rs_as_source = 1;
            end

            `OP_CMP: begin
                uses_rd_as_source = 1;
                uses_rs_as_source = 1;
            end

            `OP_ADD, `OP_SUB, `OP_AND, `OP_OR: begin
                reg_write = 1;
                uses_rd_as_source = 1;
                uses_rs_as_source = 1;
            end

            `OP_INC, `OP_DEC, `OP_NEG: begin
                reg_write = 1;
                uses_rd_as_source = 1;
            end

            `OP_LDI: begin
                reg_write = 1;
                is_two_word = 1;
            end

            `OP_LDS: begin
                reg_write = 1;
                mem_read = 1;
                mem_to_reg = 1;
                is_two_word = 1;
            end

            `OP_STS: begin
                mem_write = 1;
                is_two_word = 1;
                uses_rd_as_source = 1;
            end

            `OP_JMP: begin
                jump = 1;
                is_two_word = 1;
            end

            `OP_BEQ, `OP_BNE, `OP_BGT, `OP_BLT: begin
                branch = 1;
                is_two_word = 1;
            end
        endcase
    end
endmodule

// ALU
module alu(
    input [4:0] opcode,
    input [15:0] a,
    input [15:0] b,
    input [15:0] imm,
    output reg [15:0] result
);
    always @(*) begin
        case (opcode)
            `OP_MOV: result = b;
            `OP_CMP: result = a - b;
            `OP_ADD: result = a + b;
            `OP_SUB: result = a - b;
            `OP_LDI: result = imm;
            `OP_LDS: result = imm;
            `OP_STS: result = imm;
            `OP_INC: result = a + 16'd1;
            `OP_DEC: result = a - 16'd1;
            `OP_NEG: result = -a;
            `OP_AND: result = a & b;
            `OP_OR : result = a | b;
            default: result = 16'd0;
        endcase
    end
endmodule

// Hazard unit
module hazard_unit(
    input is_two_word,
    input has_second_word,
    input id_ex_mem_read,
    input [2:0] id_ex_rd,
    input [2:0] if_id_rd,
    input [2:0] if_id_rs,
    input uses_rd_as_source,
    input uses_rs_as_source,
    output need_second_word_stall,
    output load_use_stall,
    output stall
);
    assign need_second_word_stall = is_two_word && !has_second_word;

    assign load_use_stall = id_ex_mem_read &&
                            ((uses_rd_as_source && (id_ex_rd == if_id_rd)) ||
                             (uses_rs_as_source && (id_ex_rd == if_id_rs)));

    assign stall = need_second_word_stall || load_use_stall;
endmodule

// Forwarding unit
module forwarding_unit(
    input ex_mem_reg_write,
    input [2:0] ex_mem_rd,
    input mem_wb_reg_write,
    input [2:0] mem_wb_rd,
    input [2:0] id_ex_rd_src,
    input [2:0] id_ex_rs,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (ex_mem_reg_write && (ex_mem_rd == id_ex_rd_src))
            forward_a = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd == id_ex_rd_src))
            forward_a = 2'b01;

        if (ex_mem_reg_write && (ex_mem_rd == id_ex_rs))
            forward_b = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd == id_ex_rs))
            forward_b = 2'b01;
    end
endmodule

// IF/ID pipeline register
module if_id_pipeline(
    input clk,
    input reset,
    input flush,
    input write_first_word,
    input write_second_word,
    input [15:0] instr_in,
    input [15:0] second_word_in,
    output reg [15:0] instr_out,
    output reg [15:0] second_word_out,
    output reg has_second_word
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instr_out <= 16'd0;
            second_word_out <= 16'd0;
            has_second_word <= 1'b0;
        end else if(flush) begin 
            instr_out <= 16'd0;
            second_word_out <= 16'd0;
            has_second_word <= 1'b0;
        end else begin
            if (write_first_word) begin
                instr_out <= instr_in;
                second_word_out <= 16'd0;
                has_second_word <= 1'b0;
            end

            if (write_second_word) begin
                second_word_out <= second_word_in;
                has_second_word <= 1'b1;
            end
        end
    end
endmodule

// ID/EX pipeline register
module id_ex_pipeline(
    input clk,
    input reset,
    input flush,
    input [4:0] opcode_in,
    input [2:0] rd_in,
    input [2:0] rs_in,
    input [15:0] a_in,
    input [15:0] b_in,
    input [15:0] imm_in,
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input mem_to_reg_in,
    input branch_in,
    input jump_in,
    output reg [4:0] opcode_out,
    output reg [2:0] rd_out,
    output reg [2:0] rs_out,
    output reg [15:0] a_out,
    output reg [15:0] b_out,
    output reg [15:0] imm_out,
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out,
    output reg branch_out,
    output reg jump_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode_out <= 5'd0;
            rd_out <= 3'd0;
            rs_out <= 3'd0;
            a_out <= 16'd0;
            b_out <= 16'd0;
            imm_out <= 16'd0;
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
        end else if(flush) begin 
            opcode_out <= 5'd0;
            rd_out <= 3'd0;
            rs_out <= 3'd0;
            a_out <= 16'd0;
            b_out <= 16'd0;
            imm_out <= 16'd0;
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
        end else begin
            opcode_out <= opcode_in;
            rd_out <= rd_in;
            rs_out <= rs_in;
            a_out <= a_in;
            b_out <= b_in;
            imm_out <= imm_in;
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out <= branch_in;
            jump_out <= jump_in;
        end
    end
endmodule

// EX/MEM pipeline register
module ex_mem_pipeline(
    input clk,
    input reset,
    input [4:0] opcode_in,
    input [2:0] rd_in,
    input [15:0] alu_result_in,
    input [15:0] store_data_in,
    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input mem_to_reg_in,
    output reg [4:0] opcode_out,
    output reg [2:0] rd_out,
    output reg [15:0] alu_result_out,
    output reg [15:0] store_data_out,
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode_out <= 5'd0;
            rd_out <= 3'd0;
            alu_result_out <= 16'd0;
            store_data_out <= 16'd0;
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            opcode_out <= opcode_in;
            rd_out <= rd_in;
            alu_result_out <= alu_result_in;
            store_data_out <= store_data_in;
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule

// MEM/WB pipeline register
module mem_wb_pipeline(
    input clk,
    input reset,
    input [4:0] opcode_in,
    input [2:0] rd_in,
    input [15:0] alu_result_in,
    input [15:0] mem_data_in,
    input reg_write_in,
    input mem_to_reg_in,
    output reg [4:0] opcode_out,
    output reg [2:0] rd_out,
    output reg [15:0] alu_result_out,
    output reg [15:0] mem_data_out,
    output reg reg_write_out,
    output reg mem_to_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode_out <= 5'd0;
            rd_out <= 3'd0;
            alu_result_out <= 16'd0;
            mem_data_out <= 16'd0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            opcode_out <= opcode_in;
            rd_out <= rd_in;
            alu_result_out <= alu_result_in;
            mem_data_out <= mem_data_in;
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule

module pipeline_cpu(
    input clk,
    input reset
    // output[3:0] r1,
    // output[3:0] r2,
    // output[3:0] r3,
    // output[3:0] r4,
    // output[3:0] r5,
    // output[3:0] r6,
    // output[3:0] r7
);
    reg [15:0] pc;
    wire [15:0] instr_from_imem;

    instruction_memory IMEM(
        .addr(pc),
        .instr(instr_from_imem)
    );

    // IF/ID
    wire [15:0] if_id_instr;
    wire [15:0] if_id_second_word;
    wire if_id_has_second_word;

    wire [4:0] if_id_opcode = if_id_instr[15:11];
    wire [2:0] if_id_rd     = if_id_instr[10:8];
    wire [2:0] if_id_rs     = if_id_instr[7:5];

    // Control
    wire ctrl_reg_write;
    wire ctrl_mem_read;
    wire ctrl_mem_write;
    wire ctrl_mem_to_reg;
    wire ctrl_branch;
    wire ctrl_jump;
    wire ctrl_is_two_word;
    wire ctrl_uses_rd_as_source;
    wire ctrl_uses_rs_as_source;

    control_unit CU(
        .opcode(if_id_opcode),
        .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .mem_to_reg(ctrl_mem_to_reg),
        .branch(ctrl_branch),
        .jump(ctrl_jump),
        .is_two_word(ctrl_is_two_word),
        .uses_rd_as_source(ctrl_uses_rd_as_source),
        .uses_rs_as_source(ctrl_uses_rs_as_source)
    );

    // ID/EX
    wire [4:0] id_ex_opcode;
    wire [2:0] id_ex_rd, id_ex_rs;
    wire [15:0] id_ex_a, id_ex_b, id_ex_imm;
    wire id_ex_reg_write, id_ex_mem_read, id_ex_mem_write;
    wire id_ex_mem_to_reg, id_ex_branch, id_ex_jump;

    // EX/MEM
    wire [4:0] ex_mem_opcode;
    wire [2:0] ex_mem_rd;
    wire [15:0] ex_mem_alu_result;
    wire [15:0] ex_mem_store_data;
    wire ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write, ex_mem_mem_to_reg;

    // MEM/WB
    wire [4:0] mem_wb_opcode;
    wire [2:0] mem_wb_rd;
    wire [15:0] mem_wb_alu_result;
    wire [15:0] mem_wb_mem_data;
    wire mem_wb_reg_write;
    wire mem_wb_mem_to_reg;

    wire [15:0] wb_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

    // Register file
    wire [15:0] reg_a;
    wire [15:0] reg_b;

    register_file RF(
        .clk(clk),
        .reset(reset),
        .reg_write(mem_wb_reg_write),
        .read_addr1(if_id_rd),
        .read_addr2(if_id_rs),
        .write_addr(mem_wb_rd),
        .write_data(wb_data),
        .read_data1(reg_a),
        .read_data2(reg_b)
        // .r1(r1),
        // .r2(r2),
        // .r3(r3),
        // .r4(r4),
        // .r5(r5),
        // .r6(r6),
        // .r7(r7)
    );

    // Hazard unit
    wire need_second_word_stall;
    wire load_use_stall;
    wire stall;

    hazard_unit HU(
        .is_two_word(ctrl_is_two_word),
        .has_second_word(if_id_has_second_word),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rd(if_id_rd),
        .if_id_rs(if_id_rs),
        .uses_rd_as_source(ctrl_uses_rd_as_source),
        .uses_rs_as_source(ctrl_uses_rs_as_source),
        .need_second_word_stall(need_second_word_stall),
        .load_use_stall(load_use_stall),
        .stall(stall)
    );

    // Branch logic needs branch_taken, declared before IF/ID connections
    wire branch_condition;
    wire branch_taken;

    wire flush_if_id = branch_taken;
    wire write_first_word  = !stall && !branch_taken;
    wire write_second_word = need_second_word_stall && !branch_taken;

    if_id_pipeline IF_ID(
        .clk(clk),
        .reset(reset),
        .flush(flush_if_id),
        .write_first_word(write_first_word),
        .write_second_word(write_second_word),
        .instr_in(instr_from_imem),
        .second_word_in(instr_from_imem),
        .instr_out(if_id_instr),
        .second_word_out(if_id_second_word),
        .has_second_word(if_id_has_second_word)
    );

    wire flush_id_ex = stall || branch_taken;

    id_ex_pipeline ID_EX(
        .clk(clk),
        .reset(reset),
        .flush(flush_id_ex),
        .opcode_in(if_id_opcode),
        .rd_in(if_id_rd),
        .rs_in(if_id_rs),
        .a_in(reg_a),
        .b_in(reg_b),
        .imm_in(if_id_second_word),
        .reg_write_in(ctrl_reg_write),
        .mem_read_in(ctrl_mem_read),
        .mem_write_in(ctrl_mem_write),
        .mem_to_reg_in(ctrl_mem_to_reg),
        .branch_in(ctrl_branch),
        .jump_in(ctrl_jump),

        .opcode_out(id_ex_opcode),
        .rd_out(id_ex_rd),
        .rs_out(id_ex_rs),
        .a_out(id_ex_a),
        .b_out(id_ex_b),
        .imm_out(id_ex_imm),
        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump)
    );

    // Forwarding
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit FU(
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .id_ex_rd_src(id_ex_rd),
        .id_ex_rs(id_ex_rs),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    wire [15:0] alu_a = (forward_a == 2'b10) ? ex_mem_alu_result :
                        (forward_a == 2'b01) ? wb_data :
                        id_ex_a;

    wire [15:0] alu_b = (forward_b == 2'b10) ? ex_mem_alu_result :
                        (forward_b == 2'b01) ? wb_data :
                        id_ex_b;

    wire [15:0] alu_result;

    alu ALU(
        .opcode(id_ex_opcode),
        .a(alu_a),
        .b(alu_b),
        .imm(id_ex_imm),
        .result(alu_result)
    );

    // Status register
    reg Z;
    reg N;

    wire updates_flags =
        (id_ex_opcode == `OP_CMP) ||
        (id_ex_opcode == `OP_ADD) ||
        (id_ex_opcode == `OP_SUB) ||
        (id_ex_opcode == `OP_INC) ||
        (id_ex_opcode == `OP_DEC) ||
        (id_ex_opcode == `OP_NEG) ||
        (id_ex_opcode == `OP_AND) ||
        (id_ex_opcode == `OP_OR);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Z <= 0;
            N <= 0;
        end else if (updates_flags) begin
            Z <= (alu_result == 0);
            N <= alu_result[15];
        end
    end
    
    assign branch_condition =
        (id_ex_opcode == `OP_BEQ) ? Z :
        (id_ex_opcode == `OP_BNE) ? !Z :
        (id_ex_opcode == `OP_BGT) ? (!Z && !N) :
        (id_ex_opcode == `OP_BLT) ? N :
        1'b0;

    assign branch_taken = id_ex_jump || (id_ex_branch && branch_condition);

    ex_mem_pipeline EX_MEM(
        .clk(clk),
        .reset(reset),
        .opcode_in(id_ex_opcode),
        .rd_in(id_ex_rd),
        .alu_result_in(alu_result),
        .store_data_in(alu_a),
        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_to_reg_in(id_ex_mem_to_reg),
        .opcode_out(ex_mem_opcode),
        .rd_out(ex_mem_rd),
        .alu_result_out(ex_mem_alu_result),
        .store_data_out(ex_mem_store_data),
        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg)
    );

    // MEM stage
    wire [15:0] ram_read_data;

    data_ram RAM(
        .clk(clk),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_store_data),
        .read_data(ram_read_data)
    );

    mem_wb_pipeline MEM_WB(
        .clk(clk),
        .reset(reset),
        .opcode_in(ex_mem_opcode),
        .rd_in(ex_mem_rd),
        .alu_result_in(ex_mem_alu_result),
        .mem_data_in(ram_read_data),
        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .opcode_out(mem_wb_opcode),
        .rd_out(mem_wb_rd),
        .alu_result_out(mem_wb_alu_result),
        .mem_data_out(mem_wb_mem_data),
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg)
    );

    // PC 
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 16'd0;
        end else begin
            if (branch_taken) begin
                pc <= id_ex_imm;
            end else if (need_second_word_stall) begin
                pc <= pc + 16'd1;
            end else if (!load_use_stall) begin
                pc <= pc + 16'd1;
            end
        end
    end
endmodule
