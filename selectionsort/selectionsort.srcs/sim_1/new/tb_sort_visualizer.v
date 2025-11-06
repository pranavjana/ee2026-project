`timescale 1ns / 1ps

module tb_sort_visualizer;
    reg clk;
    reg reset;
    reg sw13;
    
    wire cs, sdin, sclk, d_cn, resn, vccen, pmoden;
    
    // Instantiate the top module
    sort_visualizer_top uut (
        .clk_100MHz(clk),
        .reset(reset),
        .sw13(sw13),
        .cs(cs),
        .sdin(sdin),
        .sclk(sclk),
        .d_cn(d_cn),
        .resn(resn),
        .vccen(vccen),
        .pmoden(pmoden)
    );
    
    // Generate 100MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz = 10ns period
    end
    
    // Test sequence
    initial begin
        $display("Starting Sort Visualizer Testbench");
        
        // Initialize
        reset = 1;
        sw13 = 0;
        #100;
        
        // Release reset
        reset = 0;
        $display("Reset released at time %0t", $time);
        #1000;
        
        // Turn on switch 13 to start sorting
        sw13 = 1;
        $display("Switch 13 ON - Sorting should start at time %0t", $time);
        
        // Wait for sorting to complete (approximately 30 seconds in real time)
        // In simulation, we'll wait enough cycles to see the sorting process
        #50000000; // 50ms simulation time
        
        // Turn off switch 13
        sw13 = 0;
        $display("Switch 13 OFF at time %0t", $time);
        #10000;
        
        // Turn on again to restart sort
        sw13 = 1;
        $display("Switch 13 ON again - Sort should restart at time %0t", $time);
        #50000000;
        
        $display("Testbench completed");
        $finish;
    end
    
    // Monitor array values during sorting
    always @(posedge uut.clk_sort) begin
        if (sw13) begin
            $display("Time: %0t | State: %0d | i: %0d | j: %0d | min_idx: %0d | Array: [%0d,%0d,%0d,%0d,%0d,%0d]",
                $time, 
                uut.sort_ctrl.state,
                uut.current_i,
                uut.current_j,
                uut.min_idx,
                uut.array_flat[2:0], uut.array_flat[5:3], uut.array_flat[8:6],
                uut.array_flat[11:9], uut.array_flat[14:12], uut.array_flat[17:15]);
        end
    end

endmodule