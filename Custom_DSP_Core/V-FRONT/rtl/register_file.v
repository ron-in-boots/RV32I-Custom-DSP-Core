// Register file of the CPU- Upgraded with 3rd Read Port and write through bypassing
// Created:     2024-01-20
// Modified:    2026-04-12
// Author:      Kagan Dikmen/Aayan


module register_file
    #(
    parameter RF_ADDR_LEN = 5,
    parameter RF_DATA_LEN = 32
    )(
    input clk,
    input rst,
    input w_en,

    input [RF_ADDR_LEN-1:0] rs1_addr,
    input [RF_ADDR_LEN-1:0] rs2_addr,
    input [RF_ADDR_LEN-1:0] rs3_addr,      // NEW: 3rd port address

    input [RF_ADDR_LEN-1:0] rd_addr,

    output reg [RF_DATA_LEN-1:0] rs1_data,
    output reg [RF_DATA_LEN-1:0] rs2_data,
    output reg [RF_DATA_LEN-1:0] rs3_data, // NEW: 3rd port data
    input [RF_DATA_LEN-1:0] rd_write_data
    );

    `include "../lib/common_library.vh"

    integer i;
    reg [RF_DATA_LEN-1:0] rf [2**RF_ADDR_LEN-1:0];

    // resetting
    always @(posedge clk)
    begin
        if (rst == 1'b1)
        begin
            for (i = 0; i<2**RF_ADDR_LEN; i = i+1)
            begin
                rf[i] <= 'b0;
            end
        end
        else if (w_en == 1'b1)  // synchronous write
            rf[rd_addr] <= rd_write_data;

        rf[0] <= 'b0;           // x0 always has the value 32'h00000000
    end

    // asynchronous Read WITH Write-Through Bypassing (The Blind Spot Fix)
    always @(*) begin
        rs1_data = (w_en && rd_addr != 0 && rd_addr == rs1_addr) ? rd_write_data : rf[rs1_addr];
        rs2_data = (w_en && rd_addr != 0 && rd_addr == rs2_addr) ? rd_write_data : rf[rs2_addr];
        rs3_data = (w_en && rd_addr != 0 && rd_addr == rs3_addr) ? rd_write_data : rf[rs3_addr];
    end

endmodule