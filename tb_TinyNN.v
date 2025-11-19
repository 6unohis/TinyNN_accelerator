/***************************************************************************
 * Copyright (C) 2025 Intelligent System Architecture (ISA) Lab. All rights reserved. 
 * 
 * This file is written solely for academic use in AI Accelerator Design course assignment 
 * In School of Electrical and Electronics Engineering, Konkuk University 
 *
 * Unauthorized distribution is strictly prohibited.
 ***************************************************************************/
 
`timescale 1ns/1ns

module tb_top ();
    // Clock and control signals
    reg         clk, rst, run;
    reg         batch_mode;         // 0: 8-batch, 1: 16-batch
    wire [3:0]  state;             // Accelerator state
    wire        busy;              // Accelerator busy signal
    
    // Memory interface signals
    wire        re_X, re_W1, re_W2;
    wire [6:0]  addr_X, addr_Y;
    wire [5:0]  addr_W1, addr_W2;
    wire [7:0]  data_X, data_W1, data_W2;
    wire [15:0] data_Y;
    
    // Control signals for memory access from testbench
    reg         we_X_ext, re_Y_ext;
    reg  [6:0]  addr_X_ext, addr_Y_ext;
    reg  [7:0]  din_X_ext;
    
    // Memory enable and address multiplexing
    wire        en_X = we_X_ext || re_X;
    wire        we_X = we_X_ext;
    wire [6:0]  addr_X_mux = we_X_ext ? addr_X_ext : addr_X;
    wire [7:0]  din_X = we_X_ext ? din_X_ext : 8'd0;
    
    wire [6:0]  addr_Y_mux = re_Y_ext ? addr_Y_ext : addr_Y;
    wire [15:0] dout_Y;
    
    parameter TEST_MODE = 1;         // 0: BASE (8-batch), 1: EXTRA (16-batch)
    parameter PROJECT_DIR = "C:/Users/nond5/Desktop/2025/ai_proj/";    
    
    mem_behavior #(.firmware({PROJECT_DIR, "data/model/w1_hex.txt"}), .bitline(8), .bitaddr(6), .binary(0))  
        U_mem_W1 ( .clk(clk), .en(re_W1), .we(1'b0),  .addr(addr_W1), .din(8'd0), .dout(data_W1) );
        
    mem_behavior #(.firmware({PROJECT_DIR, "data/model/w2_hex.txt"}), .bitline(8), .bitaddr(6), .binary(0))  
        U_mem_W2 ( .clk(clk), .en(re_W2), .we(1'b0),  .addr(addr_W2), .din(8'd0), .dout(data_W2) );

    mem_behavior #(.firmware({PROJECT_DIR, TEST_MODE ? "data/inout_extra/y_hex.txt" : "data/inout_base/y_hex.txt"}), .bitline(16), .bitaddr(7), .binary(0))  
        U_mem_Y  ( .clk(clk), .en(re_Y_ext), .we(1'b0),  .addr(addr_Y_ext), .din(8'd0), .dout(dout_Y) );

    mem_behavior #(.firmware({PROJECT_DIR, TEST_MODE ? "data/inout_extra/x_hex.txt" : "data/inout_base/x_hex.txt"}), .bitline(8), .bitaddr(6+TEST_MODE), .binary(0))  
        U_mem_X  ( .clk(clk),  .en(en_X),  .we(we_X),  .addr(addr_X_mux[5 + TEST_MODE : 0]),  .din(din_X),  .dout(data_X) );

    nn_accelerator U_nn_accel (
        .clk(clk),.rst(rst),.run(run),.batch_mode(batch_mode),.state(state),.busy(busy),
        .re_X(re_X),.addr_X(addr_X),.data_X(data_X),
        .re_W1(re_W1),.addr_W1(addr_W1),.data_W1(data_W1),
        .re_W2(re_W2),.addr_W2(addr_W2),.data_W2(data_W2),
        .re_Y_ext(re_Y_ext), .addr_Y_ext(addr_Y_ext), .data_Y(data_Y)
    );
    
    always #5 clk <= ~clk;
    
    task check_output;
        input [31:0] batch_size;
        integer i;
        integer total_elements;
        reg signed [15:0] result;
        integer error_flag;
        begin
            total_elements = batch_size * 8;
            error_flag = 0;
            
            repeat(8) @(posedge clk);
            re_Y_ext <= 1'b1;
            for (i = 0; i < total_elements; i = i + 1) begin

                addr_Y_ext <= i;
                repeat(3) @(posedge clk);
                result = data_Y;
                
                if (i % 8 == 0) begin
                    $display("");
                    $write("Batch %0d Output [%2d:%2d]: ", i/8, i, i+7);
                end
                $write("%04h > ", dout_Y);
                $write("%04h(%4d) ", result, $signed(result));

                if(dout_Y != result) error_flag = 1;
                if (i % 8 == 7) $display("");
            end

            if(error_flag) $write("Error occured!");
            else $write("Success!");
            
            @(posedge clk);
            re_Y_ext <= 1'b0;
            
        end
    endtask
    
    task run_nn_test;
        input [31:0] batch_size;
        begin
            $display("\n=== Starting Neural Network Test ===");
            $display("MODE : %s >> Batch size: %0d", TEST_MODE ? "EXTRA" : "BASE", batch_size);
            
            // Configure batch mode
            batch_mode <= (batch_size == 16) ? 1'b1 : 1'b0;
            
            // Start accelerator
            @(posedge clk);
            run <= 1'b1;
            
            @(posedge clk);
            run <= 1'b0;
            
            // Wait for completion
            $display("\n NN processtarted...");
            @(posedge clk);
            while (busy) begin
                @(posedge clk);
            end
            
            $display("Time %0t: Neural Network Processing Complete!", $time);
            
            #100;
            check_output(batch_size);
        end
    endtask
    
    // Performance monitoring
    integer cycle_count;
    integer cycles_per_element_int;
    integer cycles_per_element_frac;
    
    always @(posedge clk) begin
        if (run)
            cycle_count <= 0;
        else if (busy)
            cycle_count <= cycle_count + 1;
    end
    
    initial begin
        clk <= 1'b0; rst <= 1'b0; run <= 1'b0; batch_mode <= 1'b0;
        we_X_ext <= 1'b0; re_Y_ext <= 1'b0;
        addr_X_ext <= 7'd0; addr_Y_ext <= 7'd0;
        din_X_ext <= 8'd0;
        
        #100;
        rst <= 1'b1;
        #100;
        rst <= 1'b0;

        #100;
        run_nn_test(8*(TEST_MODE+1));
        cycles_per_element_int = cycle_count / (64 * (TEST_MODE + 1));
        cycles_per_element_frac = ((cycle_count % 64 * (TEST_MODE + 1)) * 100) / 64 * (TEST_MODE + 1);
        
        $display("\n=== Performance Metrics ===");
        $display("Total computation cycles: %0d", cycle_count);
        $display("Cycles per element: %0d.%02d", cycles_per_element_int, cycles_per_element_frac);
        $display("\n=== Simulation Summary ===");
        
        #100;
        $finish();
    end
    
    initial begin
        #1000000;  // 1ms timeout
        $display("ERROR: Simulation timeout!");
        $finish();
    end
    
endmodule