// Instruction decoder of the CPU - Upgraded to read physical pipeline state
// Modified:    2026-04-12
// Author:      Kagan Dikmen/ Aayan 

module instruction_decoder
    #(
    parameter OPD_LENGTH = 32,
    parameter REG_WIDTH = 32
    )(
    input clk,
    input rst,
    input [31:0] instr,
    
    output reg [4:0] rs1_addr,
    output reg [4:0] rs2_addr,
    output reg [4:0] rs3_addr,    
    output reg [4:0] rd_addr,
    
    input [REG_WIDTH-1:0] rs1_data,
    input [REG_WIDTH-1:0] rs2_data,
    input [REG_WIDTH-1:0] rs3_data,    

    // NEW: Direct Pipeline State Inputs to prevent async stall bugs
    input [4:0] rd_addr_ex,
    input [4:0] rd_addr_me,
    input w_en_rf_ex,
    input w_en_rf_me,

    output reg [OPD_LENGTH-1:0] opd1,
    output reg [OPD_LENGTH-1:0] opd2,
    output reg [OPD_LENGTH-1:0] opd3,  
    
    output bypass_ex_result_rs1,
    output bypass_ex_result_rs2,
    output bypass_ex_result_rs3,       
    
    output bypass_me_result_rs1,
    output bypass_me_result_rs2,
    output bypass_me_result_rs3        
    );

    `include "../lib/common_library.vh"

    reg rs1_sourced, rs2_sourced, rs3_sourced;

    // PHASE 2: Check the physical pipeline registers instead of a blind history buffer
    assign bypass_ex_result_rs1 = (w_en_rf_ex && (rd_addr_ex == rs1_addr) && (rd_addr_ex != 5'b0) && rs1_sourced) ? 1'b1 : 1'b0;
    assign bypass_ex_result_rs2 = (w_en_rf_ex && (rd_addr_ex == rs2_addr) && (rd_addr_ex != 5'b0) && rs2_sourced) ? 1'b1 : 1'b0;
    assign bypass_ex_result_rs3 = (w_en_rf_ex && (rd_addr_ex == rs3_addr) && (rd_addr_ex != 5'b0) && rs3_sourced) ? 1'b1 : 1'b0;
    
    assign bypass_me_result_rs1 = (w_en_rf_me && (rd_addr_me == rs1_addr) && (rd_addr_me != 5'b0) && rs1_sourced) ? 1'b1 : 1'b0;
    assign bypass_me_result_rs2 = (w_en_rf_me && (rd_addr_me == rs2_addr) && (rd_addr_me != 5'b0) && rs2_sourced) ? 1'b1 : 1'b0;
    assign bypass_me_result_rs3 = (w_en_rf_me && (rd_addr_me == rs3_addr) && (rd_addr_me != 5'b0) && rs3_sourced) ? 1'b1 : 1'b0;

    always @(*)
    begin        
        rd_addr = instr [11:7];
        rs1_addr = instr [19:15];
        rs2_addr = instr [24:20];
        rs3_addr = instr [11:7];

        opd1 = rs1_data;
        opd2 = rs2_data;
        opd3 = rs3_data;           

        case(instr[6:0])
            R_OPCODE:
            begin
                rs1_sourced = 1'b1;
                rs2_sourced = 1'b1;
                if (instr[31:25] == 7'b0000010 && instr[14:12] == 3'b000) begin
                    rs3_sourced = 1'b1;
                end else begin
                    rs3_sourced = 1'b0;
                end
            end
            I_OPCODE: begin rs1_sourced = 1'b1; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            LOAD_OPCODE: begin rs1_sourced = 1'b1; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            S_OPCODE: begin rs1_sourced = 1'b1; rs2_sourced = 1'b1; rs3_sourced = 1'b0; end
            B_OPCODE: begin rs1_sourced = 1'b1; rs2_sourced = 1'b1; rs3_sourced = 1'b0; end
            JAL_OPCODE: begin rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            JALR_OPCODE: begin rs1_sourced = 1'b1; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            LUI_OPCODE: begin rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            AUIPC_OPCODE: begin rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            FENCE_OPCODE: begin rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
            SYSTEM_OPCODE:
            begin
                if(instr[14:12] == FUNCT3_ECALL_EBREAK) begin
                    rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0;
                end else begin
                    rs1_sourced = 1'b1; rs2_sourced = 1'b0; rs3_sourced = 1'b0;
                end
            end
            default: begin rs1_sourced = 1'b0; rs2_sourced = 1'b0; rs3_sourced = 1'b0; end
        endcase
    end
endmodule