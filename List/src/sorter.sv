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
    localparam LENGTH_WIDTH = (LENGTH > 1) ? $clog2(LENGTH) : 1
)(
    input wire clk, rst,
    input wire [LENGTH*DATA_WIDTH-1:0] data_in,
    input wire [$clog2(LENGTH+1)-1:0] len,
    input wire sort_en,
    input wire sort_order, // 0: unsigned ascending; 1: unsigned descending.
    output reg [LENGTH*DATA_WIDTH-1:0] data_sorted,
    output reg sort_done,
    output reg sort_in_progress
);
    localparam IDLE = 2'd0, NEXT_KEY = 2'd1, COMPARE = 2'd2, WAIT_RELEASE = 2'd3;
    reg [1:0] state;
    reg [DATA_WIDTH-1:0] items [0:LENGTH-1];
    reg [DATA_WIDTH-1:0] key;
    reg [LENGTH_WIDTH-1:0] key_index, position;
    reg [$clog2(LENGTH+1)-1:0] count;
    reg descending;
    integer packed_item, item;

    always @(*) begin
        for (packed_item = 0; packed_item < LENGTH; packed_item = packed_item + 1)
            data_sorted[packed_item*DATA_WIDTH +: DATA_WIDTH] = items[packed_item];
    end

    generate
        if (DATA_WIDTH < 1 || LENGTH < 1) begin : gen_invalid
            initial $fatal(1, "Invalid sorter parameters");
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            key <= 0;
            key_index <= 0;
            position <= 0;
            descending <= 0;
            sort_done <= 0;
            sort_in_progress <= 0;
            for (item = 0; item < LENGTH; item = item + 1)
                items[item] <= 0;
        end else begin
            case (state)
                IDLE: if (sort_en) begin
                    count <= (len > LENGTH) ? LENGTH : len;
                    descending <= sort_order;
                    key_index <= (LENGTH > 1) ? 1 : 0;
                    for (item = 0; item < LENGTH; item = item + 1)
                        items[item] <= (item < len) ? data_in[item*DATA_WIDTH +: DATA_WIDTH] : 0;
                    sort_done <= (len <= 1);
                    sort_in_progress <= (len > 1);
                    state <= (len <= 1) ? WAIT_RELEASE : NEXT_KEY;
                end
                NEXT_KEY: begin
                    key <= items[key_index];
                    position <= key_index;
                    state <= COMPARE;
                end
                COMPARE: begin
                    if (position != 0 &&
                        ((!descending && items[position-1] > key) ||
                         (descending && items[position-1] < key))) begin
                        items[position] <= items[position-1];
                        position <= position - 1'b1;
                    end else begin
                        items[position] <= key;
                        if (key_index == count - 1) begin
                            sort_done <= 1'b1;
                            sort_in_progress <= 1'b0;
                            state <= WAIT_RELEASE;
                        end else begin
                            key_index <= key_index + 1'b1;
                            state <= NEXT_KEY;
                        end
                    end
                end
                WAIT_RELEASE: if (!sort_en) begin
                    sort_done <= 1'b0;
                    sort_in_progress <= 1'b0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
