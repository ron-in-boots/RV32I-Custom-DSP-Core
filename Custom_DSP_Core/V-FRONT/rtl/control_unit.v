// Control unit of the CPU - Upgraded for MAC (Phase 2)
// Created:     2024-01-20
// Modified:    2026-04-11
// Author: Kagan Dikmen / Aayan

module control_unit
    (
    input clk, input rst, input stall, output fetch_instr, input [31:0] instr, input is_misaligned,
    output reg alu_imm_select, output reg [1:0] alu_pc_select, output reg [1:0] rf_w_select,
    output reg alu_cu_input_sel, output reg [1:0] alu_subunit_res_sel, output reg [3:0] alu_subunit_op_sel,
    output reg sat_en,                  
    output reg mac_en,                  // NEW: Multiplier enable flag
    output reg w_en_rf_if, output reg branch, output reg jump, output reg ecall,
    output reg ebreak, output reg mret, output reg [3:0] ldst_mask, output reg ldst_is_unsigned,
    output reg st_en_if, output csr_r_en, output csr_w_en, output [2:0] csr_op,
    output [11:0] csr_addr, output [1:0] csr_imm_select, input branch_true, output make_nop
    );

    `include "../lib/common_library.vh"
    wire [16:0] instr_compressed;
    reg branch_id, jump_id, ecall_id, ebreak_id, mret_id;
    reg branch_ex, jump_ex, ecall_ex, ebreak_ex, mret_ex;
    reg make_nop_id, make_nop_ex, make_nop_if_buffer;
    reg csr_r_en_if, csr_r_en_id, csr_r_en_ex;
    reg csr_w_en_if, csr_w_en_id, csr_w_en_ex;
    reg [2:0] csr_op_if, csr_op_id, csr_op_ex;
    reg [11:0] csr_addr_if, csr_addr_id, csr_addr_ex;
    reg [1:0] csr_imm_select_if, csr_imm_select_id, csr_imm_select_ex;
    
    assign csr_r_en = (is_misaligned && !make_nop_ex) ? 1'b1 : csr_r_en_ex;
    assign csr_w_en = (is_misaligned && !make_nop_ex) ? 1'b0 : csr_w_en_ex;
    assign csr_op = (is_misaligned && !make_nop_ex) ? 3'b000 :csr_op_ex;
    assign csr_addr = (is_misaligned && !make_nop_ex) ? CSR_MTVEC_ADDR : csr_addr_ex;
    assign csr_imm_select = (is_misaligned && !make_nop_ex) ? 2'b10 : csr_imm_select_ex;
    assign fetch_instr = 1'b1; assign make_nop = make_nop_ex;
    assign instr_compressed = {instr[14:12], instr[6:0]};

    always @(posedge clk) begin
        if(rst) begin
            branch_id <= 0; jump_id <= 0; ecall_id <= 0; ebreak_id <= 0; mret_id <= 0;
            branch_ex <= 0; jump_ex <= 0; ecall_ex <= 0; ebreak_ex <= 0; mret_ex <= 0;
            make_nop_id <= 0; make_nop_ex <= 0;
            csr_r_en_id <= 0; csr_w_en_id <= 0; csr_op_id <= 0; csr_addr_id <= 0; csr_imm_select_id <= 0;
            csr_r_en_ex <= 0; csr_w_en_ex <= 0; csr_op_ex <= 0; csr_addr_ex <= 0; csr_imm_select_ex <= 0;
        end else if (!stall) begin // <-- NEW: Freeze pipeline on stall
            branch_id <= branch; jump_id <= jump; ecall_id <= ecall;
            ebreak_id <= ebreak; mret_id <= mret;
            branch_ex <= branch_id; jump_ex <= jump_id; ecall_ex <= ecall_id; ebreak_ex <= ebreak_id;
            mret_ex <= mret_id;
            make_nop_id <= make_nop_if_buffer; make_nop_ex <= make_nop_if_buffer || make_nop_id;
            csr_r_en_id <= csr_r_en_if; csr_w_en_id <= csr_w_en_if; csr_op_id <= csr_op_if;
            csr_addr_id <= csr_addr_if; csr_imm_select_id <= csr_imm_select_if;
            csr_r_en_ex <= csr_r_en_id; csr_w_en_ex <= csr_w_en_id; csr_op_ex <= csr_op_id; csr_addr_ex <= csr_addr_id;
            csr_imm_select_ex <= csr_imm_select_id;
        end
    end

    always @(*) begin
        alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0;
        alu_imm_select = 1; alu_pc_select = 0;      
        sat_en = 0; mac_en = 0; // Default off
        branch = 0; jump = 0; st_en_if = 0; csr_r_en_if = 0; csr_w_en_if = 0;
        csr_addr_if = 0; csr_imm_select_if = 0; csr_op_if = 0;
        mret = 0; ecall = 0; ebreak = 0; ldst_is_unsigned = 0; ldst_mask = 0; w_en_rf_if = 0;
        
        case (instr_compressed)
            {FUNCT3_ADD, R_OPCODE}: begin
                case (instr[31:25])
                    7'b0000000: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0000; w_en_rf_if = 1; rf_w_select = 0; sat_en = 0; mac_en = 0; end
                    7'b0100000: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b1000; w_en_rf_if = 1; rf_w_select = 0; sat_en = 0; mac_en = 0; end
                    7'b0000001: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0000; w_en_rf_if = 1; rf_w_select = 0; sat_en = 1; mac_en = 0; end
                    7'b0100001: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b1000; w_en_rf_if = 1; rf_w_select = 0; sat_en = 1; mac_en = 0; end
                    7'b0000010: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0000; w_en_rf_if = 1; rf_w_select = 0; sat_en = 0; mac_en = 1; end // MAC!
                    default: begin w_en_rf_if = 0; end
                endcase
            end
            {FUNCT3_SLL, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0011; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SLT, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b11; alu_subunit_op_sel = 4'b0011; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SLTU, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b11; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_XOR, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0100; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SRL, R_OPCODE}: begin
                if (instr[30] == 0) begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0001; w_en_rf_if = 1; rf_w_select = 0; end
                else begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            end
            {FUNCT3_OR, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0110; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_AND, R_OPCODE}: begin alu_imm_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_ADDI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b00; alu_subunit_op_sel = 4'b0000; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SLTI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b11; alu_subunit_op_sel = 4'b0011; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SLTIU, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b11; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_XORI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0100; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_ORI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0110; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_ANDI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b01; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SLLI, I_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0011; w_en_rf_if = 1; rf_w_select = 0; end
            {FUNCT3_SRLI, I_OPCODE}: begin
                if (instr[30] == 0) begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0001; w_en_rf_if = 1; rf_w_select = 0; end
                else begin alu_cu_input_sel = 0; alu_subunit_res_sel = 2'b10; alu_subunit_op_sel = 4'b0111; w_en_rf_if = 1; rf_w_select = 0; end
            end
            {FUNCT3_LB, LOAD_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 2'b01; ldst_mask = 4'b0001; end
            {FUNCT3_LH, LOAD_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 2'b01; ldst_mask = 4'b0011; end
            {FUNCT3_LW, LOAD_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 2'b01; ldst_mask = 4'b1111; end
            {FUNCT3_LBU, LOAD_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 2'b01; ldst_is_unsigned = 1; ldst_mask = 4'b0001; end
            {FUNCT3_LHU, LOAD_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 2'b01; ldst_is_unsigned = 1; ldst_mask = 4'b0011; end
            {FUNCT3_SB, S_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; ldst_mask = 4'b0001; st_en_if = 1; end
            {FUNCT3_SH, S_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; ldst_mask = 4'b0011; st_en_if = 1; end
            {FUNCT3_SW, S_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; ldst_mask = 4'b1111; st_en_if = 1; end
            {FUNCT3_BEQ, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_BNE, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0001; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_BLT, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0011; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_BGE, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0010; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_BLTU, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0111; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_BGEU, B_OPCODE}: begin alu_pc_select = 2'b01; alu_cu_input_sel = 1; alu_subunit_res_sel = 0; alu_subunit_op_sel = 4'b0110; branch = 1; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_FENCE, FENCE_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_FENCEI, FENCE_OPCODE}: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; end
            {FUNCT3_ECALL_EBREAK, SYSTEM_OPCODE}: begin
                alu_pc_select = 0; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; alu_imm_select = 1; w_en_rf_if = 0; rf_w_select = 0; csr_r_en_if = 1; csr_w_en_if = 0; csr_op_if = 0;
                case (instr[31:20])
                    12'h000: begin ecall = 1; csr_addr_if = CSR_MTVEC_ADDR; end
                    12'h001: begin ebreak = 1; csr_addr_if = CSR_MTVEC_ADDR; end
                    12'h302: begin mret = 1; csr_addr_if = CSR_MEPC_ADDR; end
                endcase
            end
            {FUNCT3_CSRRW, SYSTEM_OPCODE}: begin alu_pc_select = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; alu_imm_select = 1; w_en_rf_if = (instr[11:7] == 5'b0) ? 0 : 1; rf_w_select = 2'b11; csr_r_en_if = (instr[11:7] == 5'b0) ? 0 : 1; csr_w_en_if = 1; csr_addr_if = instr[31:20]; csr_op_if = 3'b001; end
            {FUNCT3_CSRRS, SYSTEM_OPCODE}: begin alu_pc_select = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; alu_imm_select = 1; w_en_rf_if = 1; rf_w_select = 2'b11; csr_r_en_if = 1; csr_w_en_if = (instr[19:15] == 5'b0) ? 0: 1; csr_addr_if = instr[31:20]; csr_op_if = 3'b010; end
            {FUNCT3_CSRRC, SYSTEM_OPCODE}: begin alu_pc_select = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; alu_imm_select = 1; w_en_rf_if = 1; rf_w_select = 2'b11; csr_r_en_if = 1; csr_w_en_if = (instr[19:15] == 5'b0) ? 0: 1; csr_addr_if = instr[31:20]; csr_op_if = 3'b011; end
            {FUNCT3_CSRRWI, SYSTEM_OPCODE}: begin w_en_rf_if = (instr[11:7] == 5'b0) ? 0 : 1; rf_w_select = 2'b11; csr_r_en_if = (instr[11:7] == 5'b0) ? 0 : 1; csr_w_en_if = 1; csr_addr_if = instr[31:20]; csr_imm_select_if = 2'b01; csr_op_if = 3'b101; end
            {FUNCT3_CSRRSI, SYSTEM_OPCODE}: begin w_en_rf_if = 1; rf_w_select = 2'b11; csr_r_en_if = 1; csr_w_en_if = (instr[19:15] == 5'b0) ? 0: 1; csr_addr_if = instr[31:20]; csr_imm_select_if = 2'b01; csr_op_if = 3'b110; end
            {FUNCT3_CSRRCI, SYSTEM_OPCODE}: begin w_en_rf_if = 1; rf_w_select = 2'b11; csr_r_en_if = 1; csr_w_en_if = (instr[19:15] == 5'b0) ? 0: 1; csr_addr_if = instr[31:20]; csr_imm_select_if = 2'b01; csr_op_if = 3'b111; end
            default: begin
                case (instr[6:0])
                    JAL_OPCODE: begin alu_pc_select = 2'b01; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; jump = 1; w_en_rf_if = 1; rf_w_select = 2'b10; end
                    JALR_OPCODE: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; jump = 1; w_en_rf_if = 1; rf_w_select = 2'b10; end
                    LUI_OPCODE: begin alu_pc_select = 2'b10; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 0; end
                    AUIPC_OPCODE: begin alu_pc_select = 2'b01; alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 1; rf_w_select = 0; end
                    default: begin alu_cu_input_sel = 0; alu_subunit_res_sel = 0; alu_subunit_op_sel = 0; w_en_rf_if = 0; rf_w_select = 0; end
                endcase
            end
        endcase

        if(((branch_ex && branch_true) || jump_ex || ecall_ex || ebreak_ex || mret_ex || is_misaligned) && !make_nop_ex) make_nop_if_buffer = 1;
        else make_nop_if_buffer = 0;
    end
endmodule