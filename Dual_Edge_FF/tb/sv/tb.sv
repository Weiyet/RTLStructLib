`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 09/22/2024 01:42:52 PM
// Created By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 13/06/2025 09:23 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Module Name: tb
// Description: Testbench for dual_edge_ff module.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
    );
    // DUT parameter
    localparam DUT_DATA_WIDTH = 8;
    localparam DUT_RESET_VALUE = 0; // Max number of nodes in the list
    
    // TB parameter
    localparam TB_CLK_PERIOD = 25;
    localparam TB_TEST_WEIGHT = 1;
    localparam SIM_TIMEOUT = 500000;

integer err_cnt = 0;

// input 
reg clk = 0;
reg rst_n = 1;
reg [DUT_DATA_WIDTH-1:0] data_in = 0;
reg [DUT_DATA_WIDTH-1:0] pos_edge_latch_en = 0;
reg [DUT_DATA_WIDTH-1:0] neg_edge_latch_en = 0;
// output
wire [DUT_DATA_WIDTH-1:0] data_out; 

`ifdef XILINX_GLS
    // for xilinx gate sim
    glbl glbl();
`endif



   dual_edge_ff #(
        .DATA_WIDTH(DUT_DATA_WIDTH),   
        .RESET_VALUE(DUT_RESET_VALUE) 
    ) DUT (
       /*input  wire                  */.clk(clk),
       /*input  wire                  */.rst_n(rst_n),
       /*input  wire [DATA_WIDTH-1:0] */.data_in(data_in),
       /*input  wire [DATA_WIDTH-1:0] */.pos_edge_latch_en(pos_edge_latch_en),
       /*input  wire [DATA_WIDTH-1:0] */.neg_edge_latch_en(neg_edge_latch_en),
       /*output wire [DATA_WIDTH-1:0] */.data_out(data_out)
    );
    
always #(TB_CLK_PERIOD/2) clk = ~clk; 

integer i = 0;
integer j = 0;
reg [DUT_DATA_WIDTH-1:0] target_data_wr;

task direct_test();
begin
   $display("Starting direct operation test");
   for (i = 0; i<50; i=i+1) begin
        j = $urandom_range(0,2);
        case (j)
            0: begin //posedge only 
               @ (negedge clk) // change data_in at negedge, expect DUT to latch at next posedge 
               #1;
               pos_edge_latch_en= 2**DUT_DATA_WIDTH -1;
               target_data_wr = $urandom;
               data_in = target_data_wr;
               @ (posedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect at posedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end else begin
                    $display("%0t Data out is correctly latched at posedge with value %0d", $realtime, data_out); 
               end
              
               data_in = target_data_wr + 1;
               @ (negedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect, should not be updated at posedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end
               pos_edge_latch_en = 1'b0;
               
            end
            1: begin //negedge only 
               @ (posedge clk) // change data in at posedge, expect DUT to latch at next negedge 
               #1;
               neg_edge_latch_en= 2**DUT_DATA_WIDTH -1;
               target_data_wr = $urandom;
               data_in = target_data_wr;
               @ (negedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect at negedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end else begin
                    $display("%0t Data out is correctly latched at negedge with value %0d", $realtime, data_out); 
               end

               data_in = target_data_wr + 1;
               @ (posedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect, should not be updated at posedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end
               neg_edge_latch_en = 1'b0;
               
            end
            default: begin // both edge 
               @ (posedge clk) // change data in at posedge, expect DUT to latch at next negedge 
               #1;
               neg_edge_latch_en= 2**DUT_DATA_WIDTH -1;
               pos_edge_latch_en= 2**DUT_DATA_WIDTH -1;
               target_data_wr = $urandom;
               data_in = target_data_wr;
               @ (negedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect at negedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end else begin
                    $display("%0t Data out is correctly latched at negedge with value %0d", $realtime, data_out); 
               end
               
               target_data_wr = $urandom;
               data_in = target_data_wr;
               @ (posedge clk) 
               #1;
               if (data_out != target_data_wr) begin
                    $error("%0t Data out is incorrect at posedge, EXP: %0d, ACT: %0d",$realtime, target_data_wr, data_out);
                    err_cnt = err_cnt + 1;               
               end else begin
                    $display("%0t Data out is correctly latched at posedge with value %0d", $realtime, data_out); 
               end
               neg_edge_latch_en= 0;
               pos_edge_latch_en= 0;
            end
        
        endcase;
        
   end


end
endtask

initial begin
    string vcdfile;
    int vcdlevel;
    int seed;
    int temp;

    rst_n = 1'b0;
    if ($value$plusargs("VCDFILE=%s",vcdfile))
        $dumpfile(vcdfile);
    if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
        $dumpvars(vcdlevel,tb);
    if ($value$plusargs("SEED=%d",seed)) begin
        temp = $urandom(seed);
        $display("Seed = %0d",seed);
    end
    #100;
    rst_n = 1'b1;
    direct_test();
    
    #1000;
    
    if (err_cnt > 0) begin
        $display("\n%0t TEST FAILED",$realtime);
        $display("Error count = %0d\n", err_cnt);
    end else
        $display("\n%0t TEST PASSED\n", $realtime);
    $finish;
end

initial begin
    #(SIM_TIMEOUT)
    $display("\n%0t TEST FAILED", $realtime);
    $display("SIM TIMEOUT!\n");
    $finish;
end

endmodule

