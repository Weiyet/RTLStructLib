`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sorter
// Create Date: 12/05/2025 11:32 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 19/06/2025 09:25 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 
// Additional Comments: Just simpler insertion sort
// 
//////////////////////////////////////////////////////////////////////////////////

module sorter #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH = 8, 
    localparam LENGTH_WIDTH =  $clog2(LENGTH)
)(
    input  wire                               clk,
    input  wire                               rst,
    // input wire [LENGTH_WIDTH-1:0][DATA_WIDTH-1] data_in, // yosys does not support 2d packed array so we need to use 1d packed array 
    input  wire [LENGTH*DATA_WIDTH-1:0]       data_in,
    input  wire [$clog2(LENGTH+1)-1:0]        len, //current length of valid data_in
    input  wire                               sort_en,
    input  wire                               sort_order, // 0 for ascending, 1 for descending
    // input wire [LENGTH_WIDTH-1:0][DATA_WIDTH-1] data_sorted, // yosys does not support 2d packed array so we need to use 1d packed array 
    output reg  [LENGTH*DATA_WIDTH-1:0]       data_sorted,
    output reg                                sort_done,
    output reg                                sort_in_progress
);

    localparam IDLE = 3'b000;
    localparam NEXT_KEY = 3'b001;
    localparam COMP_AND_SWAP = 3'b010;
    localparam SORT_DONE = 3'b011; 
    
    integer i;
    reg [DATA_WIDTH-1:0]              data_sorted_unpacked [LENGTH-1:0];
    reg [DATA_WIDTH-1:0]              data_in_unpacked [LENGTH-1:0];
    reg [LENGTH_WIDTH-1:0]            key_ptr;
    reg [LENGTH_WIDTH-1:0]            cur_ptr;
    reg [DATA_WIDTH-1:0]              temp;
    reg [2:0]                         current_state;


    // icarus does not support stream unpacking, so we need to do it manually
    // always @ (*) begin
    //     data_in_unpacked = {>> DATA_WIDTH {data_in}};
    // end 
    always @(*) begin
        for (i = 0; i < LENGTH; i = i + 1) begin
            data_in_unpacked[i] = data_in[i*DATA_WIDTH +: DATA_WIDTH];
        end
    end
    // icarus does not support stream unpacking, so we need to do it manually
    
    // icarus does not support stream packing, so we need to do it manually
    // always @ (*) begin
    //     data_sorted = {>> DATA_WIDTH {data_sorted_unpacked}}; 
    // end 
    always @(*) begin
        for (i = 0; i < LENGTH; i = i + 1) begin
            data_sorted[i*DATA_WIDTH +: DATA_WIDTH] = data_sorted_unpacked[i];
        end
    end
    // icarus does not support stream packing, so we need to do it manually


    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            sort_done <= 1'b0;
            sort_in_progress <= 1'b0;
            current_state <= IDLE;
            for(i=0; i<LENGTH; i=i+1) begin
                data_sorted_unpacked[i] <= 'b0;
            end
        end else begin
            case(current_state)
                IDLE:begin
                    if(sort_en) begin
                        current_state <= NEXT_KEY;
                        key_ptr <= 'd0;
                        cur_ptr <= 'd0;
                        // icarus does not support direct assignment of 2d array....
                        //data_sorted_unpacked <= data_in_unpacked; 
                        for (i = 0; i < LENGTH; i = i + 1) begin
                            data_sorted_unpacked[i] <= data_in_unpacked[i];
                        end
                        // icarus does not support direct assignment of 2d array....
                        sort_in_progress <= 1'b1;
                        sort_done <= 1'b0;
                    end else begin
                        sort_in_progress <= 1'b0;
                        sort_done <= 1'b0;
                    end
                end
                
                NEXT_KEY: begin
                    if(key_ptr < (len-1)) begin
                        key_ptr <= key_ptr + 1;
                        temp <= data_in_unpacked[key_ptr + 1];
                        cur_ptr <= key_ptr + 1 - 'd1;
                        current_state <= COMP_AND_SWAP;
                    end else begin
                        current_state <= SORT_DONE;
                        // icarus does not support direct assignment of 2d array....
                        //data_sorted_unpacked <= data_sorted_unpacked; 
                        for (i = 0; i < LENGTH; i = i + 1) begin
                            data_sorted_unpacked[i] <= data_sorted_unpacked[i];
                        end
                        // icarus does not support direct assignment of 2d array....
                        sort_done <= 1'b1;
                        sort_in_progress <= 1'b0;
                    end
                end
                
                COMP_AND_SWAP: begin
                    if(!sort_order) begin
                        if(data_sorted_unpacked[cur_ptr] > temp) begin
                            data_sorted_unpacked[cur_ptr+1] <= data_sorted_unpacked[cur_ptr];
                            data_sorted_unpacked[cur_ptr] <= temp;
                            cur_ptr <= cur_ptr - 'b1;
                            current_state <= (cur_ptr > 'd0) ? COMP_AND_SWAP : NEXT_KEY;
                        end else if (data_sorted_unpacked[cur_ptr] <= temp | cur_ptr == 'b0) begin
                            data_sorted_unpacked[cur_ptr+1] <= temp;
                            current_state <= NEXT_KEY;
                        end                        
                    end else begin
                        if(data_sorted_unpacked[cur_ptr] < temp) begin
                            data_sorted_unpacked[cur_ptr+1] <= data_sorted_unpacked[cur_ptr];
                            data_sorted_unpacked[cur_ptr] <= temp;
                            cur_ptr <= cur_ptr - 'b1;
                            current_state <= (cur_ptr > 'd0) ? COMP_AND_SWAP : NEXT_KEY;
                        end else if(data_sorted_unpacked[cur_ptr] >= temp | cur_ptr == 'b0) begin
                            data_sorted_unpacked[cur_ptr+1] <= temp;
                            current_state <= NEXT_KEY;
                        end
                    end
                end
                
                SORT_DONE: begin
                    current_state <= IDLE;
                    sort_done <= 1'b0;
                    sort_in_progress <= 1'b0;
                end
            endcase
        end
    end
    
endmodule