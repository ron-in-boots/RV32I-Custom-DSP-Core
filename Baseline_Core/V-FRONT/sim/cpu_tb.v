// Testbench for the main body of the CPU
// Created:     2024-01-26
// Modified:    2025-05-29 (Updated for Custom FIR Filter)
// Author:      Kagan Dikmen / User

`timescale 1ns/1ns

module cpu_tb
    #(
        parameter MEM_INIT_FILE = "fir_baseline.mem",
        parameter TOHOST_ADDR    = 16384 // Kept so module parameters don't break
    )(
    );

    reg rst, sysclk_t;
    wire led_t;

    // Instantiate the CPU
    cpu #(.DMEM_ADDR_WIDTH(13), .DMEM_DATA_WIDTH(32), .OP_LENGTH(32), .PC_WIDTH(16), .MEM_INIT_FILE(MEM_INIT_FILE)) 
        cpu_ut 
        (
            .rst(rst),
            .sysclk(sysclk_t),
            .led(led_t)
        );
    
    // Generate a 10ns clock period
    always #5 sysclk_t = ~sysclk_t;
    
    initial
    begin
        // Initialize inputs
        rst = 1'b0;
        sysclk_t = 1'b0;
        
        // Assert Reset
        #4;
        rst = ~rst;

        // De-assert Reset (The CPU officially starts running here)
        #20;
        rst = ~rst;

        // --- NEW LOGIC ---
        // Let the simulation run for 10,000 ns (1,000 clock cycles).
        // This is enough time for the FIR loop to finish.
        // If your baseline takes longer, you can increase this number (e.g., #50000).
        #100000;
        
        $display("Simulation Finished! Check the Waveforms.");
        $finish;
        
    end

endmodule