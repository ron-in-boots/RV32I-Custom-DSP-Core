// Shifter of the ALU
// Created:     2024-01-18
// Modified:    2025-06-03
// Author:      Kagan Dikmen

module shifter
    #(
    parameter OPD_LENGTH = 32
    )(
    input signed [OPD_LENGTH-1:0] opd1,
    input [OPD_LENGTH-1:0] opd2,
    input [3:0] alu_op_select,      // 0001 for SRL/SRLI, 0011 for SLL/SLLI, 0111 for SRA/SRAI

    output [OPD_LENGTH-1:0] shifter_result
    );

    localparam SRL_SRLI = 3'b001;
    localparam SLL_SLLI = 3'b011;
    localparam SRA_SRAI = 3'b111;

    reg [OPD_LENGTH-1:0] shifter_result_bf;

    assign shifter_result = shifter_result_bf;

    always @(*)
    begin
        case (alu_op_select[2:0])
            SRL_SRLI:   shifter_result_bf = opd1 >> opd2[4:0];
            SLL_SLLI:   shifter_result_bf = opd1 << opd2[4:0];
            SRA_SRAI:   shifter_result_bf = opd1 >>> opd2[4:0];
            default: 
            begin
                shifter_result_bf = 'b0;
            end
        endcase
    end

endmodule