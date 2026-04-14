// Sequential Multiplier for MAC Instruction - PHASE 2
// Modified:    2026-04-12
// Author:      Aayan 

module multiplier
    #(
    parameter OPERAND_LENGTH = 32
    )(
    input clk,
    input rst,
    input en,                     
    input [OPERAND_LENGTH-1:0] a, // rs1
    input [OPERAND_LENGTH-1:0] b, // rs2
    
    output reg [OPERAND_LENGTH-1:0] product,
    output done                
    );

    // Phase 2: True 2-cycle sequential behavior.
    // Cycle 1 (Stalled EX): Multiplier calculates a*b and registers it.
    // Cycle 2 (Active EX): product is valid, ALU combinatorially adds it to acc_in.
    
    always @(posedge clk) begin
        if (rst) begin
            product <= 'b0;
        end else if (en) begin
            product <= a * b;
        end
    end

    // The CPU hazard controller handles the latency natively now, 
    // keeping this high to satisfy the ALU module's port list.
    assign done = 1'b1;

endmodule