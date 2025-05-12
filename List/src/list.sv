`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: list
// Create Date: 07/05/2025 07:51 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 12/05/2025 12:23 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: List 
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////


module list #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH = 8,
    parameter SUM_METHOD = 0, // 0: parallel (combo) sum, 1: sequentia sum, 2: adder tree. //ICARUS does not support string overriden to parameter in CLI. 
    localparam LENGTH_WIDTH =  $clog2(LENGTH+1)
)(
    input  wire                                clk,
    input  wire                                rst,
    input  wire [1:0]                          op_sel,
    input  wire                                op_en,
    input  wire [DATA_WIDTH-1:0]               data_in,
    input  wire [LENGTH_WIDTH-1:0]             index_in,
    output reg  [LENGTH_WIDTH+DATA_WIDTH-1:0]  data_out,  
    output reg                                 op_done,
    output reg                                 op_error
);

  //  localparam LENGTH_WIDTH = $clog2(LENGTH+1) 
    
    localparam IDLE        = 3'b000;
    localparam SUM         = 3'b001;
    localparam SORT        = 3'b010;
    localparam SEARCH      = 3'b011;
    localparam ACCESS_DONE = 3'b100;
    
    reg [$clog2(LENGTH+1)-1:0]       data_count;
    reg [LENGTH-1:0][DATA_WIDTH-1:0] data_stored; // could implement with RAM for large size of data
    reg [DATA_WIDTH*LENGTH-1:0]      data_stored_packed;
    reg [2:0]                        current_state;
    wire                             op_is_write; 
    wire                             op_is_read;
    wire                             op_is_find_all_index;
    wire                             op_is_find_1st_index;
    wire                             op_is_sum;
    wire                             op_is_sort_asc;
    wire                             op_is_sort_des;
    //ADDER
    reg                                sum_en;
    wire                               sum_done;
    wire                               sum_in_progress;
    wire [LENGTH_WIDTH+DATA_WIDTH-1:0] sum_result;
    //SORT
    reg                                sort_en;
    reg                                sort_order;
    wire                               sort_done;
    wire                               sort_in_progress;
    wire [LENGTH-1:0][DATA_WIDTH-1:0]  data_sorted;
  
    integer i;
    
    assign op_is_read = (op_sel == 3'b000) & op_en;
    assign op_is_write = (op_sel == 3'b001) & op_en;
    assign op_is_find_all_index = (op_sel == 3'b010) & op_en;
    assign op_is_find_1st_index = (op_sel == 3'b011) & op_en;
    assign op_is_sum = (op_sel == 3'b100) & op_en;
    assign op_is_sort_asc = (op_sel == 3'b101) & op_en;
    assign op_is_sort_des = (op_sel == 3'b110) & op_en;
    
//    always @ (*) begin
//        data_stored_packed = {<< DATA_WIDTH {data_stored}};
//    end
    
     adder #(.DATA_WIDTH(DATA_WIDTH), 
             .LENGTH(LENGTH),
             .SUM_METHOD(SUM_METHOD))
     u_adder (.clk(clk),
              .rst(rst),
              .data_in(data_stored), 
              .sum_en(sum_en),
              .sum_result(sum_result),
              .sum_done(sum_done),
              .sum_in_progress(sum_in_progress));
              
    sorter #(.DATA_WIDTH(DATA_WIDTH),
           .LENGTH(LENGTH))
    u_sorter (.clk(clk),
            .rst(rst),
            .data_in(data_stored),
            .sort_en(sort_en),
            .sort_order(sort_order), 
            .sort_done(sort_done),
            .sort_in_progress(sort_in_progress),
            .data_sorted(data_sorted));
     
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
          sum_en <= 1'b0;
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
                        data_out <= sum_result;
                        op_done <= 1'b1;
                        op_error <= 1'b0;
                    end else if(SUM_METHOD == 1) begin //SEQUENTIAL SUM
                        current_state <= SUM;
                        sum_en <= 1'b1;
                    end else if (SUM_METHOD == 2) begin //ADDER TREE
                        current_state <= SUM;
                        sum_en <= 1'b1;
                    end
                end else if (op_is_find_all_index | op_is_find_1st_index) begin                
                    current_state <= SORT;
                end else if (op_is_sort_asc) begin
                    current_state <= SORT;
                    sort_en <= 1'b1;
                    sort_order <= 1'b0;
                end else if (op_is_sort_des) begin
                    current_state <= SORT;
                    sort_en <= 1'b1;
                    sort_order <= 1'b1;
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
