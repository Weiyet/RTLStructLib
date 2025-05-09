`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: list
// Create Date: 07/05/2025 07:51 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 09/05/2025 11:36 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: List 
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////


module list #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH = 8,
    parameter SUM_METHOD = 0, // 0: parallel sum, 1: sequentia sum, 2: adder tree. //ICARUS does not support string overriden to parameter in CLI. 
    localparam LENGTH_WIDTH =  $clog2(LENGTH+1),
    localparam DATA_OUT_WIDTH = $clog2(LENGTH)+DATA_WIDTH-1 
)(
    input                                               clk,
    input                                               rst,
    input  [1:0]                                        op_sel,
    input                                               op_en,
    input  [DATA_WIDTH-1:0]                             data_in,
    input  [$clog2(LENGTH+1)-1:0]                       index_in,
    output reg [$clog2(LENGTH+1)+DATA_WIDTH-1:0]        data_out, //FIXME 
    output reg                                          op_done,
    output reg                                          op_error
);

  //  localparam LENGTH_WIDTH = $clog2(LENGTH+1) 
    
    localparam IDLE        = 2'b00;
    localparam SUM         = 2'b01;
    localparam SORT        = 2'b10;
    localparam ACCESS_DONE = 2'b11;
    
    reg [1:0]              current_state;
    reg [LENGTH_WIDTH-1:0] data_count;
    reg [DATA_WIDTH-1:0]   data_stored [0:LENGTH-1]; // could implement with RAM for large size of data
    reg [2:0]              current_state;
    wire                   op_is_write; 
    wire                   op_is_read;
    wire                   op_is_find_all_index;
    wire                   op_is_find_1st_index;
    wire                   op_is_sum;
    wire                   op_is_sort_asc;
    wire                   op_is_sort_des;
    //ADDER
    wire                   sum_done;
    wire                   sum_in_progress;
    wire [$clog2(LENGTH+1)+DATA_WIDTH-1:0] sum_result;
    
    reg [$clog2(LENGTH+1)+DATA_WIDTH-1:0] parallel_sum;
    integer i;

    always @(*) begin
        for (i = 0; i < LENGTH; i++) begin
            parallel_sum <= parallel_sum + data_stored[i];
        end
    end
    
    assign op_is_read = (op_sel == 3'b000) & op_en;
    assign op_is_write = (op_sel == 3'b001) & op_en;
    assign op_is_find_all_index = (op_sel == 3'b010) & op_en;
    assign op_is_find_1st_index = (op_sel == 3'b011) & op_en;
    assign op_is_sum = (op_sel == 3'b100) & op_en;
    assign op_is_sort_asc = (op_sel == 3'b101) & op_en;
    assign op_is_sort_des = (op_sel == 3'b110) & op_en;
    
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            for(i = 0; i < LENGTH; i++) begin
                data_stored[i] <= {(DATA_WIDTH){1'b0}};    
            end     
            data_count = {(LENGTH_WIDTH){1'b0}};
        end else if (op_is_write) begin
            data_stored[index_in] <= data_in;
            data_count <= data_count + 1 ;
        end
    end
    
    always @ (posedge clk, posedge rst) begin
       if(rst) begin
          current_state <= IDLE;
          op_done <= 1'b1;
          op_error <= 1'b0;
          data_out <= 'b0;
       end else begin
          case(current_state) 
            IDLE: begin
                if(op_is_write) begin
                    current_state <= ACCESS_DONE;
                    op_done <= 1'b1;
                    op_error <= 1'b0;
                end else if (op_is_read) begin
                    current_state <= ACCESS_DONE;
                    data_out <= data_stored[index_in]; //need buffer stage if RAM instances is used for data_stored.
                    op_done <= 1'b1;
                    op_error <= 1'b0;
                end else if (op_is_sum) begin
                    if(SUM_METHOD == 0) begin //PARALLEL SUM
                        current_state <= ACCESS_DONE;
                        data_out <= parallel_sum;
                        op_done <= 1'b1;
                        op_error <= 1'b0;
                    end else if(SUM_METHOD == 1) begin //SEQUENTIAL SUM
                        current_state <= SUM;
                    end else if (SUM_METHOD == 2) begin //ADDER TREE
                        current_state <= SUM;
                    end
                end else if (op_is_sort_asc) begin
                    current_state <= SORT;
                end else if (op_is_sort_des) begin
                    current_state <= SORT;
                end else if(op_en) begin // OP selected is not available : OP_ERROR
                    current_state <= ACCESS_DONE;
                    op_done <= 1'b1;
                    op_error <= 1'b0;
                end else begin
                   current_state <= IDLE;
                   op_done <= 1'b0;
                   op_error <= 1'b0;
                end
            end
          SUM: if(sum_done) begin
                   current_state <= ACCESS_DONE;
                   data_out <= sum_result;
                   op_done <= 1'b0;
                   op_error <= 1'b0;
               end else begin
                   current_state <= SUM;
               end
          ACCESS_DONE: begin 
                       current_state <= IDLE;
                       op_done <= 1'b0;
                       op_error <= 1'b0;
          end
          default: begin
                   current_state <= IDLE;
          end
          endcase
       end       
    end 
endmodule
