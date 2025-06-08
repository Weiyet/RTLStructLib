`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: adder
// Create Date: 11/05/2025 01:58 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 08/06/2025 09:47 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module adder #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH = 8, //need not to be power of 2
    parameter SUM_METHOD = 0, // 0: parallel (combo) sum, 1: sequential sum, 2: adder tree. //ICARUS does not support string overriden to parameter in CLI. 
    localparam LENGTH_WIDTH =  $clog2(LENGTH),
    localparam DATA_OUT_WIDTH = $clog2(LENGTH)+DATA_WIDTH-1 
)(
    input  wire                               clk,
    input  wire                               rst,
    input  wire [LENGTH-1:0][DATA_WIDTH-1:0]  data_in,
    input  wire                               sum_en,
    output reg  [LENGTH_WIDTH+DATA_WIDTH-1:0] sum_result,
    output reg                                sum_done,
    output reg                                sum_in_progress
);

    localparam NO_OF_STAGE = $clog2(LENGTH);
    localparam STG_PTR_WIDTH = $clog2(NO_OF_STAGE);
    localparam TOTAL_INPUT_INT = 2**NO_OF_STAGE; // round up to integer, LENGTH needs not to be in power of 2. 
    
    reg [LENGTH_WIDTH-1:0] cur_ptr;
    reg [STG_PTR_WIDTH-1:0] stg_ptr;
    reg [DATA_WIDTH-1:0] output_stage[TOTAL_INPUT_INT-1:0][NO_OF_STAGE-1:0];

    generate 
    if(SUM_METHOD == 0) begin  //: parallel sum (Combo) 
        integer i;
        always @(*) begin
            for(i=0; i<LENGTH; i=i+1) begin
                if(i == 0) 
                    sum_result = data_in[i];
                else 
                    sum_result = sum_result + data_in[i];
            end
            sum_done = sum_en;
            sum_in_progress = 1'b0;
        end
    end else if(SUM_METHOD == 1) begin //: sequential sum (
        always @(posedge clk, posedge rst) begin
            if(rst) begin
                sum_result <= 'b0;
                cur_ptr <= 'b0;
                sum_done <= 1'b0;
                sum_in_progress <= 1'b0;
            end else if(!sum_en) begin
                sum_done <= 1'b0;
                sum_in_progress <= 1'b0;
                cur_ptr <= 'b0;
            end else if(sum_en & cur_ptr < (LENGTH-1)) begin
                sum_result <= sum_result + data_in[cur_ptr*DATA_WIDTH +: DATA_WIDTH];
                cur_ptr <= cur_ptr + 'b1;
                sum_in_progress <= 1'b1;
            end else if(sum_en & !sum_done & cur_ptr == (LENGTH-1))begin
                sum_result <= sum_result + data_in[cur_ptr*DATA_WIDTH +: DATA_WIDTH];
                sum_done <= 1'b1;
                sum_in_progress <= 1'b0;
            end
        end
    end else begin //: ADDER TREE
        integer i,j;
        always @ (*) begin
            for(i=0; i<TOTAL_INPUT_INT; i=i+1) begin
                if(i<LENGTH) 
                    output_stage[0][i] <= data_in[i];
                else
                    output_stage[0][i] <= 'b0;    
            end
        end
        
        always @ (posedge clk, posedge rst) begin
            if(rst) begin
                for(i=1; i<NO_OF_STAGE; i=i+1) begin
                    for(j=0; j<TOTAL_INPUT_INT; j=j+1) begin 
                        output_stage[i][j] <= 'b0;
                    end
                end
            end else if(!sum_en) begin
                for(i=1; i<NO_OF_STAGE; i=i+1) begin
                    for(j=0; j<TOTAL_INPUT_INT; j=j+1) begin 
                        output_stage[i][j] <= 'b0;
                    end
                end            
            end else if(sum_en | stg_ptr < (NO_OF_STAGE-1)) begin
                for(i=0; (i*2+1)<TOTAL_INPUT_INT; i=i+1)
                    output_stage[stg_ptr+1][i] <= output_stage[stg_ptr][i*2] + output_stage[stg_ptr][i*2+1]; // unused node will remain 0
            end
        end 
        
        always @ (posedge clk, posedge rst) begin
            if(rst) begin
                stg_ptr <= 'b0;
                sum_done <= 1'b0;
                sum_in_progress <= 1'b0;
            end else if(!sum_en) begin
                stg_ptr <= 'b0;
                sum_done <= 1'b0;
                sum_in_progress <= 1'b0;
            end else if(sum_en & stg_ptr < (NO_OF_STAGE-1)) begin
                stg_ptr <= stg_ptr + 'b1;
                sum_in_progress <= 1'b1;
            end else if(sum_en & !sum_done & stg_ptr == (NO_OF_STAGE-1)) begin
                stg_ptr <= output_stage[NO_OF_STAGE-1][0];
                sum_in_progress <= 1'b0;
                sum_done <= 1'b1;
            end
        end
    end
    endgenerate
    
endmodule