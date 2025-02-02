`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 31/01/2025 12:46:52 PM
// Last Update Date: 01/02/2024 10:37:12 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Module Name: table
// Description: Table Structure that supports multiple read, write oepration simultaneously 
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////

module table_top #(
    parameter TABLE_SIZE = 32,
    parameter DATA_WIDTH = 8, 
    parameter INPUT_RATE = 2,
    parameter OUTPUT_RATE = 2
)(
    input wire clk,
    input wire rst, 
    input wire wr_en,
    input wire rd_en,
    input wire [INPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_wr,
    input wire [OUTPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_rd,
    input wire [INPUT_RATE*DATA_WIDTH-1:0] data_wr,
    output reg [OUTPUT_RATE*DATA_WIDTH-1:0] data_rd
);
    localparam INDEX_WIDTH = $clog2(TABLE_SIZE-1);
    reg [DATA_WIDTH-1:0] data_stored [TABLE_SIZE];
    integer i;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            for (i=0; i<TABLE_SIZE; i=i+1) begin
                data_stored[i] = 'b0;
            end
        end else if (wr_en) begin
            for (i=1; i<=INPUT_RATE; i=i+1) begin
                data_stored[index_wr[i*INDEX_WIDTH-1 -:INDEX_WIDTH]] = data_wr[i*DATA_WIDTH-1 -:DATA_WIDTH];
            end            
        end
    end

    always @ (posedge clk or posedge rst) begin 
        if(rst) begin
            for (i=1; i<=OUTPUT_RATE; i=i+1) begin
                data_rd[i*DATA_WIDTH-1 -: DATA_WIDTH] = 'b0;
            end
        end else if (rd_en) begin
            for (i=1; i<=OUTPUT_RATE; i=i+1) begin
                data_rd[i*DATA_WIDTH-1 -: DATA_WIDTH] = data_stored[index_rd[i*INDEX_WIDTH-1 -:INDEX_WIDTH]];
            end            
        end
    end 



endmodule


