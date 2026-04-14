// ALU of the CPU - UPGRADED FOR SATURATING ARITHMETIC (Phase 1) -Upgraded for MAC (Phase 2)
// Created:     2024-01-17
// Modified:    2026-04-11
// Author:      Kagan Dikmen / Aayan

`include "./subunits/adder.v"
`include "./subunits/comparison_unit.v"
`include "./subunits/logic_unit.v"
`include "./subunits/mux.v"
`include "./subunits/shifter.v"
`include "./subunits/multiplier.v" 

module alu
    #(
    parameter OPERAND_LENGTH = 32
    )(
    input clk,
    input rst,
    input [OPERAND_LENGTH-1:0] opd1,
    input [OPERAND_LENGTH-1:0] opd2,
    input [OPERAND_LENGTH-1:0] opd3,
    input [OPERAND_LENGTH-1:0] opd4,
    input [OPERAND_LENGTH-1:0] acc_in,  // NEW: 3rd port for MAC
    input cu_input_sel,
    input [1:0] subunit_res_sel,
    input [3:0] subunit_op_sel,
    input sat_en,                     
    input mac_en,                       // NEW: Turn on multiplier
    output [OPERAND_LENGTH-1:0] alu_result,
    output [OPERAND_LENGTH-1:0] comp_result 
    );

    wire [OPERAND_LENGTH-1:0] adder_result;
    wire [OPERAND_LENGTH-1:0] mult_product;
    wire [OPERAND_LENGTH-1:0] cu_input1, cu_input2, logic_result, shifter_result;

    // MUX Logic: If MAC, add (Product + Accumulator). Otherwise, (opd1 + opd2).
    wire [OPERAND_LENGTH-1:0] adder_opd1 = (mac_en) ? mult_product : opd1;
    wire [OPERAND_LENGTH-1:0] adder_opd2 = (mac_en) ? acc_in : opd2;

    multiplier #(.OPERAND_LENGTH(OPERAND_LENGTH)) mult_in_alu (
        .clk(clk), .rst(rst), .en(mac_en),
        .a(opd1), .b(opd2), .product(mult_product), .done()
    );

    adder #(.OPERAND_LENGTH(OPERAND_LENGTH)) adder_in_alu (
        .opd1(adder_opd1), .opd2(adder_opd2), .alu_op_select(subunit_op_sel),
        .sat_en(sat_en), .adder_result(adder_result)
    );

    comparison_unit #(.OPD_LENGTH(OPERAND_LENGTH)) comparison_unit_in_alu (
        .opd1(cu_input1), .opd2(cu_input2), .alu_op_select(subunit_op_sel), .comp_result(comp_result)
    );

    logic_unit #(.OPD_LENGTH(OPERAND_LENGTH)) logic_unit_in_alu (
        .opd1(opd1), .opd2(opd2), .alu_op_select(subunit_op_sel), .logic_result(logic_result)
    );

    shifter #(.OPD_LENGTH(OPERAND_LENGTH)) shifter_in_alu (
        .opd1(opd1), .opd2(opd2), .alu_op_select(subunit_op_sel), .shifter_result(shifter_result)
    );

    two_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH)) cu_mux1 (.a(opd1), .b(opd3), .sel(cu_input_sel), .z(cu_input1));
    two_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH)) cu_mux2 (.a(opd2), .b(opd4), .sel(cu_input_sel), .z(cu_input2));

    four_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH)) result_mux (
        .a(adder_result), .b(logic_result), .c(shifter_result), .d(comp_result),
        .sel(subunit_res_sel), .z(alu_result)
    );
endmodule