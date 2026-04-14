// Main body of the CPU - ULTIMATE PHASE 2 (Dual-Stall Architecture)
// Modified:    2026-04-12
// Author:      Kagan Dikmen / Aayan

`include "./luftALU/rtl/alu.v"
`include "./bram_dual.v"
`include "./control_unit.v"
`include "./csr_unit.v"
`include "./immediate_generator.v"
`include "./instruction_decoder.v"
`include "./memory_access_unit.v"
`include "./mux.v"
`include "./pc_counter.v"
`include "./register_file.v"
`include "./hazard_detection_unit.v"

module cpu 
    #(
    parameter DMEM_ADDR_WIDTH = 13,
    parameter DMEM_DATA_WIDTH = 32,
    parameter OP_LENGTH = 32,
    parameter PC_WIDTH = 16,
    parameter MEM_INIT_FILE = ""
    )(
    input rst,
    input sysclk,
    output wire led     
    );

    // IF
    wire [OP_LENGTH-1:0] next_pc, pc_if;
    wire [31:0] instr_if;
    wire ctrl_fetch_instr_out;

    // ID
    reg [31:0] instr_id;
    reg [OP_LENGTH-1:0] pc_id;
    
    wire ctrl_alu_imm_select_out;
    wire [1:0] ctrl_alu_pc_select_out, ctrl_rf_w_select_out, ctrl_alu_subunit_res_sel_out;
    wire ctrl_alu_cu_input_sel_out, ctrl_w_en_rf_if_out, ctrl_branch_out, ctrl_jump_out;
    wire ctrl_ecall_out, ctrl_ebreak_out, ctrl_mret_out, ctrl_st_en_if_out;
    wire [3:0] ctrl_ldst_mask_out, ctrl_alu_subunit_op_sel_out;
    wire ctrl_ldst_is_unsigned_out;
    wire ctrl_csr_r_en_out, ctrl_csr_w_en_out;
    wire [2:0] ctrl_csr_op_out;
    wire [11:0] ctrl_csr_addr_out;
    wire [1:0] ctrl_csr_imm_select_out;
    wire ctrl_make_nop_out, ctrl_sat_en_out, ctrl_mac_en_out;

    reg alu_imm_select_id, alu_cu_input_sel_id, w_en_rf_id, branch_id, jump_id;
    reg [1:0] alu_pc_select_id, alu_subunit_res_sel_id, rf_w_select_id;
    reg ecall_id, ebreak_id, mret_id;
    reg [3:0] ldst_mask_id;
    reg ldst_is_unsigned_id;
    reg st_en_id;
    reg [3:0] alu_subunit_op_sel_id;
    reg sat_en_id, mac_en_id;

    wire [4:0] rs1_addr_id, rs2_addr_id, rs3_addr_id, rd_addr_id;
    wire bypass_ex_result_rs1_id, bypass_ex_result_rs2_id, bypass_ex_result_rs3_id;
    wire bypass_me_result_rs1_id, bypass_me_result_rs2_id, bypass_me_result_rs3_id;
    wire [31:0] imm_id;

    // EX
    reg [31:0] instr_ex;
    reg [OP_LENGTH-1:0] opd1_ex, opd2_ex, opd3_ex, imm_ex;
    reg alu_imm_select_ex, alu_cu_input_sel, w_en_rf_ex, branch_ex, jump_ex;
    reg [1:0] alu_pc_select_ex, alu_subunit_res_sel, rf_w_select_ex;
    reg ecall_ex, ebreak_ex, mret_ex;
    reg [3:0] ldst_mask_ex;
    reg ldst_is_unsigned_ex;
    reg st_en_ex;
    reg [3:0] alu_subunit_op_sel;
    reg sat_en_ex, mac_en_ex;
    wire make_nop_ex;
    reg [4:0] rd_addr_ex;
    wire [OP_LENGTH-1:0] alu_opd1, alu_opd2, alu_mux1_out, alu_mux2_out;
    wire [OP_LENGTH-1:0] alu_result, comp_result;
    reg [OP_LENGTH-1:0] pc_ex;
    reg bypass_ex_result_rs1_ex, bypass_ex_result_rs2_ex, bypass_ex_result_rs3_ex;
    reg bypass_me_result_rs1_ex, bypass_me_result_rs2_ex, bypass_me_result_rs3_ex;
    reg [OP_LENGTH-1:0] alu_result_bypass_buffer_ex, csr_result_bypass_buffer_ex;
    wire [31:0] rs1_data_ex, rs2_data_ex, rs3_data_ex;
    reg [4:0] rs1_addr_ex, rs2_addr_ex;

    wire [OP_LENGTH-1:0] csr_unit_out, csr_in;
    wire csr_unit_r_en, csr_unit_w_en;
    wire [1:0] csr_imm_select;
    wire [11:0] csr_unit_addr;
    wire [2:0] csr_unit_op;

    // ME
    wire [3:0] wr_mode;
    wire [DMEM_DATA_WIDTH-1:0] r_data;
    wire [31:0] rd_write_data;
    wire [OP_LENGTH-1:0] mem_acc_in, mem_acc_out;
    wire is_misaligned, is_misalignment_store;
    wire [DMEM_ADDR_WIDTH-1:0] dmem_addr;
    reg bypass_me_result_rs1_me, bypass_me_result_rs2_me;
    reg [OP_LENGTH-1:0] mem_result_bypass_buffer_me;
    reg make_nop_me;
    reg [1:0] rf_w_select_me;
    reg [4:0] rd_addr_me;
    reg [3:0] ldst_mask_me;
    reg ldst_is_unsigned_me;
    reg st_en_me;
    reg [OP_LENGTH-1:0] alu_result_me, alu_opd1_me, alu_opd2_me, csr_unit_out_me;
    reg w_en_rf_me;
    reg [OP_LENGTH-1:0] pc_me;
    reg [31:0] instr_me;

    // WB
    reg [OP_LENGTH-1:0] alu_result_wb, mem_acc_out_wb, csr_unit_out_wb;
    reg [1:0] rf_w_select_wb;
    reg w_en_rf_wb, make_nop_wb;
    reg [4:0] rd_addr_wb;

    wire [OP_LENGTH-1:0] pc_plus4_if;
    reg [OP_LENGTH-1:0] pc_plus4_id, pc_plus4_ex, pc_plus4_me, pc_plus4_wb;

    // ==========================================
    // DUAL-STALL HAZARD DETECTION UNIT
    // ==========================================
    wire stall_load_use;
    wire stall_global;

    hazard_detection_unit hdu_cpu (
        .clk(sysclk), .rst(rst),
        .rs1_addr_id(rs1_addr_id), .rs2_addr_id(rs2_addr_id), .rs3_addr_id(rs3_addr_id), .mac_en_id(mac_en_id),
        .rd_addr_ex(rd_addr_ex), .w_en_rf_ex(w_en_rf_ex), .rf_w_select_ex(rf_w_select_ex), .mac_en_ex(mac_en_ex),
        .stall_load_use(stall_load_use), .stall_global(stall_global)
    );

    // ==========================================
    // SEAMLESS PIPELINE REGISTERS
    // ==========================================
    always @(posedge sysclk) begin
        if (rst) begin
            instr_id <= 0; pc_id <= 0; pc_plus4_id <= 0;
            alu_imm_select_id <= 0; alu_pc_select_id <= 0; rf_w_select_id <= 0;
            alu_cu_input_sel_id <= 0; alu_subunit_res_sel_id <= 0; alu_subunit_op_sel_id <= 0;
            w_en_rf_id <= 0; branch_id <= 0; jump_id <= 0; ecall_id <= 0; ebreak_id <= 0; mret_id <= 0;
            ldst_mask_id <= 0; ldst_is_unsigned_id <= 0; st_en_id <= 0; sat_en_id <= 0; mac_en_id <= 0;
        end else if (!stall_global && !stall_load_use) begin 
            instr_id <= instr_if; pc_id <= pc_if; pc_plus4_id <= pc_plus4_if;
            alu_imm_select_id <= ctrl_alu_imm_select_out; alu_pc_select_id <= ctrl_alu_pc_select_out;
            rf_w_select_id <= ctrl_rf_w_select_out; alu_cu_input_sel_id <= ctrl_alu_cu_input_sel_out;
            alu_subunit_res_sel_id <= ctrl_alu_subunit_res_sel_out; alu_subunit_op_sel_id <= ctrl_alu_subunit_op_sel_out;
            w_en_rf_id <= ctrl_w_en_rf_if_out; branch_id <= ctrl_branch_out; jump_id <= ctrl_jump_out;
            ecall_id <= ctrl_ecall_out; ebreak_id <= ctrl_ebreak_out; mret_id <= ctrl_mret_out;
            ldst_mask_id <= ctrl_ldst_mask_out; ldst_is_unsigned_id <= ctrl_ldst_is_unsigned_out;
            st_en_id <= ctrl_st_en_if_out; sat_en_id <= ctrl_sat_en_out; mac_en_id <= ctrl_mac_en_out;
        end
    end

    always @(posedge sysclk) begin
        // If a Load-Use hazard is detected, flush the ID/EX register
        if (rst || stall_load_use) begin
            instr_ex <= 0; pc_ex <= 0; pc_plus4_ex <= 0; opd1_ex <= 0; opd2_ex <= 0; opd3_ex <= 0; imm_ex <= 0;
            alu_imm_select_ex <= 0; alu_pc_select_ex <= 0; rf_w_select_ex <= 0;
            alu_cu_input_sel <= 0; alu_subunit_res_sel <= 0; alu_subunit_op_sel <= 0;
            w_en_rf_ex <= 0; branch_ex <= 0; jump_ex <= 0; ecall_ex <= 0; ebreak_ex <= 0; mret_ex <= 0;
            ldst_mask_ex <= 0; ldst_is_unsigned_ex <= 0; st_en_ex <= 0;
            sat_en_ex <= 0; mac_en_ex <= 0; rd_addr_ex <= 0; rs1_addr_ex <= 0; rs2_addr_ex <= 0;
            bypass_ex_result_rs1_ex <= 0; bypass_ex_result_rs2_ex <= 0; bypass_ex_result_rs3_ex <= 0;
            bypass_me_result_rs1_ex <= 0; bypass_me_result_rs2_ex <= 0; bypass_me_result_rs3_ex <= 0;
        end else if (!stall_global) begin
            instr_ex <= instr_id; pc_ex <= pc_id; pc_plus4_ex <= pc_plus4_id;
            opd1_ex <= rs1_data_ex; opd2_ex <= rs2_data_ex; opd3_ex <= rs3_data_ex; imm_ex <= imm_id;
            alu_imm_select_ex <= alu_imm_select_id; alu_pc_select_ex <= alu_pc_select_id;
            rf_w_select_ex <= rf_w_select_id; alu_cu_input_sel <= alu_cu_input_sel_id;
            alu_subunit_res_sel <= alu_subunit_res_sel_id; alu_subunit_op_sel <= alu_subunit_op_sel_id;
            w_en_rf_ex <= w_en_rf_id; branch_ex <= branch_id; jump_ex <= jump_id;
            ecall_ex <= ecall_id; ebreak_ex <= ebreak_id; mret_ex <= mret_id;
            ldst_mask_ex <= ldst_mask_id; ldst_is_unsigned_ex <= ldst_is_unsigned_id;
            st_en_ex <= st_en_id; sat_en_ex <= sat_en_id; mac_en_ex <= mac_en_id;
            rd_addr_ex <= rd_addr_id; rs1_addr_ex <= rs1_addr_id; rs2_addr_ex <= rs2_addr_id;
            bypass_ex_result_rs1_ex <= bypass_ex_result_rs1_id; bypass_ex_result_rs2_ex <= bypass_ex_result_rs2_id; bypass_ex_result_rs3_ex <= bypass_ex_result_rs3_id;
            bypass_me_result_rs1_ex <= bypass_me_result_rs1_id; bypass_me_result_rs2_ex <= bypass_me_result_rs2_id; bypass_me_result_rs3_ex <= bypass_me_result_rs3_id;
        end
    end

    always @(posedge sysclk) begin
        if (rst) begin
            pc_plus4_me <= 0; rf_w_select_me <= 0; rd_addr_me <= 0; ldst_mask_me <= 0;
            ldst_is_unsigned_me <= 0; st_en_me <= 0; alu_result_me <= 0; alu_opd1_me <= 0;
            alu_opd2_me <= 0; csr_unit_out_me <= 0; w_en_rf_me <= 0; instr_me <= 0; pc_me <= 0;
            make_nop_me <= 0; bypass_me_result_rs1_me <= 0; bypass_me_result_rs2_me <= 0;
        end else if (!stall_global) begin
            pc_plus4_me <= pc_plus4_ex; rf_w_select_me <= rf_w_select_ex; rd_addr_me <= rd_addr_ex;
            ldst_mask_me <= ldst_mask_ex; ldst_is_unsigned_me <= ldst_is_unsigned_ex;
            st_en_me <= st_en_ex; alu_result_me <= alu_result; alu_opd1_me <= alu_opd1;
            alu_opd2_me <= alu_opd2; csr_unit_out_me <= csr_unit_out; w_en_rf_me <= w_en_rf_ex;
            instr_me <= instr_ex; pc_me <= pc_ex;
            make_nop_me <= make_nop_ex; 
            bypass_me_result_rs1_me <= bypass_me_result_rs1_ex; bypass_me_result_rs2_me <= bypass_me_result_rs2_ex;
        end
    end

    always @(posedge sysclk) begin
        if (rst) begin
            alu_result_wb <= 0; mem_acc_out_wb <= 0; pc_plus4_wb <= 0; csr_unit_out_wb <= 0;
            rf_w_select_wb <= 0; w_en_rf_wb <= 0; make_nop_wb <= 0; rd_addr_wb <= 0;
        end else if (!stall_global) begin
            alu_result_wb <= alu_result_me; mem_acc_out_wb <= mem_acc_out; pc_plus4_wb <= pc_plus4_me;
            csr_unit_out_wb <= csr_unit_out_me; rf_w_select_wb <= rf_w_select_me; w_en_rf_wb <= w_en_rf_me;
            make_nop_wb <= make_nop_me; rd_addr_wb <= rd_addr_me;
        end
    end

    // ==========================================
    // BYPASS BUFFERS & FORWARDING
    // ==========================================
    reg bypass_alu_ready, bypass_csr_ready, bypass_ld_ready, bypass_mem_ready;
    always @(posedge sysclk) begin
        if (rst) begin
            bypass_alu_ready <= 0; bypass_csr_ready <= 0; bypass_ld_ready <= 0; bypass_mem_ready <= 0;
            alu_result_bypass_buffer_ex <= 0; csr_result_bypass_buffer_ex <= 0; mem_result_bypass_buffer_me <= 0;
        end else if (!stall_global) begin
            bypass_alu_ready <= 0; bypass_csr_ready <= 0; bypass_ld_ready <= 0;
            if(w_en_rf_ex && !is_misaligned && !make_nop_ex) begin
                if(rf_w_select_ex == 2'b00) bypass_alu_ready <= 1'b1;
                else if(rf_w_select_ex == 2'b01) bypass_ld_ready <= 1'b1;
                else if(rf_w_select_ex == 2'b11) bypass_csr_ready <= 1'b1;
            end
            alu_result_bypass_buffer_ex <= alu_result; csr_result_bypass_buffer_ex <= csr_unit_out;
            if(w_en_rf_me && !make_nop_me) bypass_mem_ready <= 1'b1;
            else bypass_mem_ready <= 1'b0;
            mem_result_bypass_buffer_me <= rd_write_data;
        end
    end

    assign alu_opd1 = (bypass_ex_result_rs1_ex && bypass_alu_ready) ? alu_result_bypass_buffer_ex
                    : (bypass_ex_result_rs1_ex && bypass_csr_ready) ? csr_result_bypass_buffer_ex
                    : (bypass_ex_result_rs1_ex && bypass_ld_ready)  ? mem_acc_out
                    : (bypass_me_result_rs1_ex && bypass_mem_ready) ? rd_write_data : opd1_ex;

    assign alu_opd2 = (bypass_ex_result_rs2_ex && bypass_alu_ready) ? alu_result_bypass_buffer_ex
                    : (bypass_ex_result_rs2_ex && bypass_csr_ready) ? csr_result_bypass_buffer_ex
                    : (bypass_ex_result_rs2_ex && bypass_ld_ready)  ? mem_acc_out
                    : (bypass_me_result_rs2_ex && bypass_mem_ready) ? rd_write_data : opd2_ex;

    wire [OP_LENGTH-1:0] final_opd3 = (bypass_ex_result_rs3_ex && bypass_alu_ready) ? alu_result_bypass_buffer_ex
                                    : (bypass_ex_result_rs3_ex && bypass_csr_ready) ? csr_result_bypass_buffer_ex
                                    : (bypass_ex_result_rs3_ex && bypass_ld_ready)  ? mem_acc_out
                                    : (bypass_me_result_rs3_ex && bypass_mem_ready) ? rd_write_data : opd3_ex;
    
    // ==========================================
    // MODULE INSTANTIATIONS
    // ==========================================

    control_unit control_unit_cpu (
        .clk(sysclk), .rst(rst), .stall(stall_global || stall_load_use), .fetch_instr(ctrl_fetch_instr_out), .instr(instr_if),
        .is_misaligned(is_misaligned), .alu_imm_select(ctrl_alu_imm_select_out), .alu_pc_select(ctrl_alu_pc_select_out),
        .rf_w_select(ctrl_rf_w_select_out), .alu_cu_input_sel(ctrl_alu_cu_input_sel_out),
        .alu_subunit_res_sel(ctrl_alu_subunit_res_sel_out), .alu_subunit_op_sel(ctrl_alu_subunit_op_sel_out),
        .sat_en(ctrl_sat_en_out), .mac_en(ctrl_mac_en_out), .w_en_rf_if(ctrl_w_en_rf_if_out),
        .branch(ctrl_branch_out), .jump(ctrl_jump_out), .ecall(ctrl_ecall_out), .ebreak(ctrl_ebreak_out), .mret(ctrl_mret_out),
        .ldst_mask(ctrl_ldst_mask_out), .ldst_is_unsigned(ctrl_ldst_is_unsigned_out), .st_en_if(ctrl_st_en_if_out),
        .csr_r_en(csr_unit_r_en), .csr_w_en(csr_unit_w_en), .csr_op(csr_unit_op), .csr_addr(csr_unit_addr), .csr_imm_select(csr_imm_select),
        .branch_true(comp_result[0]), .make_nop(make_nop_ex)
    );

    pc_counter #(.OPD_WIDTH(OP_LENGTH), .PC_WIDTH(PC_WIDTH)) pc_counter_cpu (
        .clk(sysclk), .rst(rst), .stall(stall_global || stall_load_use), 
        .branch(branch_ex && !make_nop_ex), .jump(jump_ex && !make_nop_ex),
        .csr_sel((ecall_ex || ebreak_ex || mret_ex || is_misaligned) && !make_nop_ex),
        .alu_result(alu_result), .comp_result(comp_result), .csr_out(csr_unit_out),
        .pc_out(pc_if), .pc_plus4(pc_plus4_if), .next_pc(next_pc)
    );

    instruction_decoder #(.OPD_LENGTH(OP_LENGTH), .REG_WIDTH(32)) instruction_decoder_cpu (
        .clk(sysclk), .rst(rst), .instr(instr_id),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id), .rs3_addr(rs3_addr_id), .rd_addr(rd_addr_id),
        .rs1_data(rs1_data_ex), .rs2_data(rs2_data_ex), .rs3_data(rs3_data_ex),
        
        // NEW Wires hooked directly to the physical pipeline registers
        .rd_addr_ex(rd_addr_ex), .rd_addr_me(rd_addr_me),  
        .w_en_rf_ex(w_en_rf_ex), .w_en_rf_me(w_en_rf_me),  
        
        .bypass_ex_result_rs1(bypass_ex_result_rs1_id), .bypass_ex_result_rs2(bypass_ex_result_rs2_id), .bypass_ex_result_rs3(bypass_ex_result_rs3_id),
        .bypass_me_result_rs1(bypass_me_result_rs1_id), .bypass_me_result_rs2(bypass_me_result_rs2_id), .bypass_me_result_rs3(bypass_me_result_rs3_id)
    );
    
    immediate_generator immediate_generator_cpu (.instr(instr_id), .imm(imm_id));

    four_input_mux #(.INPUT_LENGTH(32)) alu_opd1_mux (.a(alu_opd1), .b(pc_ex), .c('b0), .sel(alu_pc_select_ex), .z(alu_mux1_out));
    two_input_mux #(.INPUT_LENGTH(32)) alu_opd2_mux (.a(alu_opd2), .b(imm_ex), .sel(alu_imm_select_ex), .z(alu_mux2_out));

    alu #(.OPERAND_LENGTH(OP_LENGTH)) alu_cpu (
        .clk(sysclk), .rst(rst), .opd1(alu_mux1_out), .opd2(alu_mux2_out), 
        .opd3(alu_opd1), .opd4(alu_opd2), .acc_in(final_opd3),     
        .cu_input_sel(alu_cu_input_sel), .subunit_res_sel(alu_subunit_res_sel), .subunit_op_sel(alu_subunit_op_sel),
        .sat_en(sat_en_ex), .mac_en(mac_en_ex),
        .alu_result(alu_result), .comp_result(comp_result)
    );

    four_input_mux #(.INPUT_LENGTH(32)) csr_unit_mux (.a(alu_opd1), .b(imm_ex), .c(instr_ex), .sel(csr_imm_select), .z(csr_in));
    
    csr_unit #(.CSR_REG_COUNT(4096)) csr_unit_cpu (
        .clk(sysclk), .rst(rst), .r_en(csr_unit_r_en && !make_nop_ex), .w_en(csr_unit_w_en && !make_nop_ex),
        .ecall(ecall_ex && !make_nop_ex), .ebreak(ebreak_ex && !make_nop_ex), .mret(mret_ex && !make_nop_ex),
        .pc(pc_ex), .op(csr_unit_op), .in(csr_in), .csr_addr(csr_unit_addr), .out(csr_unit_out),
        .is_misaligned(is_misaligned && !make_nop_ex), .is_misalignment_store(is_misalignment_store),
        .misaligned_store_value(alu_opd2), .mem_addr(alu_result[14:0]), .rd_addr(rd_addr_ex)
    );

    assign is_misaligned = ((ldst_mask_ex == 4'b1111 && alu_result[1:0] != 2'b00) || (ldst_mask_ex == 4'b0011 && alu_result[0] != 1'b0)) && !make_nop_ex;
    assign is_misalignment_store = is_misaligned && st_en_ex && !make_nop_ex;
    assign mem_acc_in = (st_en_me == 1'b1) ? alu_opd2_me : r_data;

    memory_access_unit #(.BYTE_WIDTH(8)) memory_access_unit_cpu (
        .addr_in(alu_result_me), .addr_out(dmem_addr), .ldst_mask(ldst_mask_me),
        .ldst_is_unsigned(ldst_is_unsigned_me), .st_en(st_en_me && !make_nop_me), .in(mem_acc_in), .out(mem_acc_out), .wr_mode(wr_mode)
    );

    bram_dual #(.INIT_FILE(MEM_INIT_FILE)) unified_memory_cpu (
        .addra(next_pc[14:2]), .addrb(dmem_addr), .dina(), .dinb(mem_acc_out),
        .clka(sysclk), .clkb(sysclk), .wea(), .web(wr_mode), .ena(ctrl_fetch_instr_out), 
        .enb(1'b1), .rsta(), .rstb(), .regcea(), .regceb(), .douta(instr_if), .doutb(r_data)
    );

    four_input_mux #(.INPUT_LENGTH(OP_LENGTH)) rf_write_select_mux_cpu (
        .a(alu_result_wb), .b(mem_acc_out_wb), .c(pc_plus4_wb), .d(csr_unit_out_wb),
        .sel(rf_w_select_wb), .z(rd_write_data)
    );
    
    register_file #(.RF_ADDR_LEN(5), .RF_DATA_LEN(32)) register_file_cpu (
        .clk(sysclk), .rst(rst), .w_en(w_en_rf_wb && !make_nop_wb),
        .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id), .rs3_addr(rs3_addr_id), .rd_addr(rd_addr_wb),
        .rs1_data(rs1_data_ex), .rs2_data(rs2_data_ex), .rs3_data(rs3_data_ex), .rd_write_data(rd_write_data)
    );

    assign led = branch_ex;
endmodule