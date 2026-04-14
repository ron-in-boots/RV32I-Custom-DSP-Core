// Adder of the ALU - UPGRADED FOR SATURATING ARITHMETIC (Phase 1)
// Created:     2024-01-17
// Modified:    2026-04-11
// Author:      Kagan Dikmen / Aayan

`include "./adder_unit.v"

module adder
    #(
    parameter OPERAND_LENGTH = 32
    )(
    input [OPERAND_LENGTH-1:0] opd1,
    input [OPERAND_LENGTH-1:0] opd2,
    input [3:0] alu_op_select,      // 0000 for addition, 1000 for subtraction
    input sat_en,                   // NEW: Saturation enable flag
    
    output [OPERAND_LENGTH-1:0] adder_result
    );

    wire [OPERAND_LENGTH-1:0] c_out;
    
    // NEW: Intercept the raw calculation before sending it to the output
    wire [OPERAND_LENGTH-1:0] raw_sum; 

    genvar i;

    generate

        for (i = 0; i < 1; i = i + 1)
        begin
            adder_unit rc (
                        .a(opd1[i]), 
                        .b(alu_op_select[3] ^ opd2[i]), 
                        .c_in(alu_op_select[3]), 
                        .out(raw_sum[i]),      // Changed from adder_result
                        .c_out(c_out[i])
                        );
        end

        for (i = 1; i < OPERAND_LENGTH; i = i + 1)
        begin
            adder_unit rc (
                        .a(opd1[i]), 
                        .b(alu_op_select[3] ^ opd2[i]), 
                        .c_in(c_out[i-1]), 
                        .out(raw_sum[i]),      // Changed from adder_result
                        .c_out(c_out[i])
                        );
        end
    endgenerate

    // =========================================================================
    // SATURATION LOGIC
    // =========================================================================
    
    // 1. Find the effective sign of Operand 2. (Inverted if subtracting)
    wire opd2_eff_sign = opd2[OPERAND_LENGTH-1] ^ alu_op_select[3];
    
    // 2. Check for Overflow: Occurs if opd1 and effective opd2 have the SAME sign, 
    // but the raw_sum has a DIFFERENT sign.
    wire overflow = ~(opd1[OPERAND_LENGTH-1] ^ opd2_eff_sign) & (opd1[OPERAND_LENGTH-1] ^ raw_sum[OPERAND_LENGTH-1]);
    
    // 3. Determine if we exceeded the Max Positive or Min Negative bounds
    wire is_pos_overflow = overflow & ~opd1[OPERAND_LENGTH-1];
    wire is_neg_overflow = overflow & opd1[OPERAND_LENGTH-1];
    
    // 32-bit Boundary Constants
    wire [OPERAND_LENGTH-1:0] MAX_POS = 32'h7FFFFFFF;
    wire [OPERAND_LENGTH-1:0] MIN_NEG = 32'h80000000;
    
    // 4. Output Multiplexer
    // If sat_en is high AND we overflowed, clamp it. Otherwise, output the normal math.
    assign adder_result = (sat_en & is_pos_overflow) ? MAX_POS :
                          (sat_en & is_neg_overflow) ? MIN_NEG :
                          raw_sum;

endmodule