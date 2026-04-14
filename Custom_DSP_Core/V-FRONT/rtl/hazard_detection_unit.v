// Hazard Detection Unit - Dual-Stall Architecture
// Automatically handles Load-Use Frontend Stalls and MAC Global Stalls.
// Author: Aayan

module hazard_detection_unit (
    input clk,
    input rst,

    // ID Stage Inputs (for Load-Use)
    input [4:0] rs1_addr_id,
    input [4:0] rs2_addr_id,
    input [4:0] rs3_addr_id,
    input mac_en_id,        

    // EX Stage Inputs (for Load-Use and MAC Structural Stall)
    input [4:0] rd_addr_ex, 
    input w_en_rf_ex,       
    input [1:0] rf_w_select_ex, 
    input mac_en_ex,

    // Outputs
    output reg stall_load_use, // Freezes PC, IF/ID. Flushes ID/EX.
    output reg stall_global    // Freezes entire pipeline
);

    wire mem_read_ex = (rf_w_select_ex == 2'b01);

    // ==========================================
    // MAC Structural Stall State Tracker
    // ==========================================
    reg mult_active_ex;
    always @(posedge clk) begin
        if (rst) mult_active_ex <= 1'b0;
        else if (mac_en_ex && !mult_active_ex) mult_active_ex <= 1'b1;
        else mult_active_ex <= 1'b0;
    end

    // ==========================================
    // Stall Logic Evaluation
    // ==========================================
    always @(*) begin
        stall_load_use = 1'b0;
        stall_global = 1'b0;

        // 1. Load-Use Hazard (Stall Frontend, Flush ID/EX)
        if (mem_read_ex && w_en_rf_ex && rd_addr_ex != 5'b0) begin
            if (rs1_addr_id == rd_addr_ex || rs2_addr_id == rd_addr_ex || (mac_en_id && rs3_addr_id == rd_addr_ex)) begin
                stall_load_use = 1'b1;
            end
        end

        // 2. MAC 2-Cycle Structural Stall (Freeze everything)
        if (mac_en_ex && !mult_active_ex) begin
            stall_global = 1'b1;
        end
    end
endmodule