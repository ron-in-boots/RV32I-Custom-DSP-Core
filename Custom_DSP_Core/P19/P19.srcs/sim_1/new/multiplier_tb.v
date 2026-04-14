`timescale 1ns / 1ps

module multiplier_tb();

    // Inputs to the multiplier
    reg clk;
    reg rst;
    reg en;
    reg [31:0] a;
    reg [31:0] b;

    // Outputs from the multiplier
    wire [31:0] product;
    wire done;

    // Instantiate our new hardware block
    multiplier uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .a(a),
        .b(b),
        .product(product),
        .done(done)
    );

    // Generate a clock signal (ticks every 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // The Test Sequence
    initial begin
        // 1. Hit the reset button
        rst = 1;
        en = 0;
        a = 0;
        b = 0;
        #20; 
        rst = 0;
        #10;
        
        // 2. Test Case 1: 5 * 4
        a = 32'd5;
        b = 32'd4;
        en = 1;         // Yell "Start!" to the multiplier
        
        // Wait until the multiplier yells "Done!"
        wait(done == 1'b1);
        #10;
        en = 0;         // Turn off
        
        // 3. Test Case 2: 100 * 20
        #20;
        a = 32'd100;
        b = 32'd20;
        en = 1;
        
        wait(done == 1'b1);
        #10;
        en = 0;

        // Finish simulation
        #50;
        $stop;
    end

endmodule