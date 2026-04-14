// ALU of the CPU
// Created:     2024-01-17
// Modified:    2025-06-28
// Author:      Kagan Dikmen

`include "./subunits/adder.v"
`include "./subunits/comparison_unit.v"
`include "./subunits/logic_unit.v"
`include "./subunits/mux.v"
`include "./subunits/shifter.v"

module alu
    #(
    parameter OPERAND_LENGTH = 32
    )(
    input [OPERAND_LENGTH-1:0] opd1,
    input [OPERAND_LENGTH-1:0] opd2,
    input [OPERAND_LENGTH-1:0] opd3,
    input [OPERAND_LENGTH-1:0] opd4,
    input cu_input_sel,
    input [1:0] subunit_res_sel,
    input [3:0] subunit_op_sel,
    
    output [OPERAND_LENGTH-1:0] alu_result,
    output [OPERAND_LENGTH-1:0] comp_result   // zero-extended
    );

    wire [OPERAND_LENGTH-1:0] adder_input1;
    wire [OPERAND_LENGTH-1:0] adder_result;
    
    wire [OPERAND_LENGTH-1:0] cu_input1;   // cu stands for "compare unit"
    wire [OPERAND_LENGTH-1:0] cu_input2;

    wire [OPERAND_LENGTH-1:0] logic_result;
    wire [OPERAND_LENGTH-1:0] shifter_result;


    adder #(.OPERAND_LENGTH(OPERAND_LENGTH)) 
                    adder_in_alu
                    (
                        .opd1(opd1),
                        .opd2(opd2),
                        .alu_op_select(subunit_op_sel),
                        .adder_result(adder_result)
                    );

    comparison_unit #(.OPD_LENGTH(OPERAND_LENGTH)) 
                    comparison_unit_in_alu 
                    (
                        .opd1(cu_input1),
                        .opd2(cu_input2),
                        .alu_op_select(subunit_op_sel),
                        .comp_result(comp_result)
                    );

    logic_unit #(.OPD_LENGTH(OPERAND_LENGTH)) 
                    logic_unit_in_alu 
                    (
                        .opd1(opd1),
                        .opd2(opd2),
                        .alu_op_select(subunit_op_sel),
                        .logic_result(logic_result)
                    );

    shifter #(.OPD_LENGTH(OPERAND_LENGTH)) 
                    shifter_in_alu 
                    (
                        .opd1(opd1),
                        .opd2(opd2),
                        .alu_op_select(subunit_op_sel),
                        .shifter_result(shifter_result)
                    );


    two_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH)) 
                    cu_mux1
                    (
                        .a(opd1),
                        .b(opd3),
                        .sel(cu_input_sel),
                        .z(cu_input1)
                    );

    two_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH)) 
                    cu_mux2
                    (
                        .a(opd2),
                        .b(opd4),
                        .sel(cu_input_sel),
                        .z(cu_input2)
                    );

    four_input_mux #(.INPUT_LENGTH(OPERAND_LENGTH))
                    result_mux
                    (
                        .a(adder_result),
                        .b(logic_result),
                        .c(shifter_result),
                        .d(comp_result),
                        .sel(subunit_res_sel),
                        .z(alu_result)
                    );
    
endmodule