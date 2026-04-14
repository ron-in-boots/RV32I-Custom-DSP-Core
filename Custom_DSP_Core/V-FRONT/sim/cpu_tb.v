// Testbench for the main body of the CPU
// Created:     2024-01-26
// Modified:    2026-04-11
// Author:      Kagan Dikmen / Aayan
`timescale 1ns/1ns

module cpu_tb();

    // Point this directly to your dummy memory file
    parameter MEM_INIT_FILE = "fir_custom.mem"; 
    
    reg rst, sysclk_t;
    wire led_t;

    cpu #(.DMEM_ADDR_WIDTH(13), .DMEM_DATA_WIDTH(32), .OP_LENGTH(32), .PC_WIDTH(16), .MEM_INIT_FILE(MEM_INIT_FILE)) 
        cpu_ut 
        (
            .rst(rst),
            .sysclk(sysclk_t),
            .led(led_t)
        );
    
    always #5 sysclk_t = ~sysclk_t;
    
    initial
    begin
        rst = 1'b0;
        sysclk_t = 1'b0;
        
        #4;
        rst = 1'b1;

        #20;
        rst = 1'b0;

        // Instead of waiting for a TOHOST signal, we just let the CPU run for 500ns.
        // This is plenty of time for our 6 instructions to execute.
        #500;
        
        // Use $stop instead of $finish so the Vivado waveform window stays open!
        $stop;
    end

endmodule