`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 30/07/2025 07:22 PM
// Created By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 03/08/2025 02:30 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Module Name: Dual Edge Flip Flop 
// Description: Synthesiazble structure that can latch data corresponding to dual edge of clock to achive double input and output rate. 
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////


module dual_edge_ff #(
    parameter DATA_WIDTH = 8,   
    parameter RESET_VALUE = 0 
    )(
       input  wire clk,
       input  wire rst_n,
       input  wire [DATA_WIDTH-1:0] data_in,
       input  wire [DATA_WIDTH-1:0] pos_edge_latch_en,
       input  wire [DATA_WIDTH-1:0] neg_edge_latch_en,
       output wire [DATA_WIDTH-1:0] data_out
    );
    
    reg [DATA_WIDTH-1:0] d_in_pos;
    reg [DATA_WIDTH-1:0] q_out_pos;
    reg [DATA_WIDTH-1:0] d_in_neg;
    reg [DATA_WIDTH-1:0] q_out_neg;
    

    assign clk_n = ~clk; // Invert clock for negative edge latching

    genvar i;   

    generate 
    for(i=0;i<DATA_WIDTH;i=i+1) begin
    
        assign d_in_pos[i] = data_in[i] ^ q_out_neg[i];
        always @ (posedge clk or negedge rst_n) begin
            if(!rst_n) 
                q_out_pos[i] <= RESET_VALUE[i];
            else if(pos_edge_latch_en[i])
                q_out_pos[i] <= d_in_pos[i];
        end
        
        assign d_in_neg[i] = (data_in[i] ^ q_out_pos[i]);      
        always @ (posedge clk_n or negedge rst_n) begin
            if(!rst_n)
                q_out_neg[i] <= 1'b0;
            else if(neg_edge_latch_en[i])
                q_out_neg[i] <= d_in_neg[i];
        end   
        
        assign data_out[i] = q_out_pos[i] ^ q_out_neg[i];
    end 
    endgenerate
    


endmodule
