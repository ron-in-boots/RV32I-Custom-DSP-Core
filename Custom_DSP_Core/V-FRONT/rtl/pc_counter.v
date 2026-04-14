// PC counter - Upgraded for stall (Phase 2)
// Created:     2024-01-20
// Modified:    2026-04-11
// Author: Kagan Dikmen / Aayan

module pc_counter
    #(
    parameter OPD_WIDTH = 32,
    parameter PC_WIDTH = 16
    )(
    input clk,
    input rst,
    input stall,                  // NEW: Stall signal from CPU
    input branch,
    input jump,
    input csr_sel,
    input [OPD_WIDTH-1:0] alu_result,
    input [OPD_WIDTH-1:0] comp_result,
    input [OPD_WIDTH-1:0] csr_out,
    
    output reg [OPD_WIDTH-1:0] pc_out,
    output [OPD_WIDTH-1:0] pc_plus4,
    output [OPD_WIDTH-1:0] next_pc
    );

    wire [OPD_WIDTH-1:0] pc_target;
    assign pc_plus4 = pc_out + 4;
    
    assign pc_target = (csr_sel) ? csr_out :
                       (jump || (branch && comp_result[0])) ? alu_result :
                       pc_plus4;

    // THE FIX: If stalled, hold the BRAM address right where it is.
    assign next_pc = (stall) ? pc_out : pc_target;

    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'hFFFFFFFC;       // THE FIX: Reset to -4 instead of 0
        else if (!stall)                  // Only update PC if NOT stalling
            pc_out <= next_pc;
    end
endmodule