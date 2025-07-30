`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 30/07/2025 07:22 PM
// Last Update: 30/07/2025 07:22 PM
// Module Name: Dual Edge Flip Flop 
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Synthesiazble structure that can latch data corresponding to dual edge of clock to achive double input and output rate. 
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////


module dual_edge_ff #(
    parameter DATA_WIDTH = 8    
    )(
       input  wire clk,
       input  wire rst_n,
       input  wire [DATA_WIDTH-1:0]  data_in,
       input  wire [DATA_WIDTH-1:0]  pos_edge_latch_en,
       input  wire [DATA_WIDTH-1:0]  neg_edge_latch_en,
       output wire [DATA_WIDTH-1:0] data_out
    );
endmodule
