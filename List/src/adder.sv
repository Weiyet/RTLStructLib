`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: adder
// Create Date: 11/05/2025 01:58 AM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 19/06/2025 09:25 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description:
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module adder #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH = 8,
    parameter SUM_METHOD = 0,
    localparam LENGTH_WIDTH = (LENGTH > 1) ? $clog2(LENGTH) : 1,
    localparam DATA_OUT_WIDTH = LENGTH_WIDTH + DATA_WIDTH
)(
    input wire clk, rst,
    input wire [LENGTH*DATA_WIDTH-1:0] data_in,
    input wire sum_en,
    output reg [DATA_OUT_WIDTH-1:0] sum_result,
    output reg sum_done,
    output reg sum_in_progress
);
    generate
        if (DATA_WIDTH < 1 || LENGTH < 1 || SUM_METHOD < 0 || SUM_METHOD > 2) begin : gen_invalid
            initial $fatal(1, "Invalid adder parameters");
        end
        if (SUM_METHOD == 0) begin : gen_parallel
            integer item;
            always @(*) begin
                sum_result = 0;
                for (item = 0; item < LENGTH; item = item + 1)
                    sum_result = sum_result + data_in[item*DATA_WIDTH +: DATA_WIDTH];
                sum_done = sum_en && !rst;
                sum_in_progress = 1'b0;
            end
        end else if (SUM_METHOD == 1) begin : gen_sequential
            reg [LENGTH*DATA_WIDTH-1:0] snapshot;
            reg [LENGTH_WIDTH-1:0] pointer;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    snapshot <= 0;
                    pointer <= 0;
                    sum_result <= 0;
                    sum_done <= 0;
                    sum_in_progress <= 0;
                end else if (!sum_en) begin
                    pointer <= 0;
                    sum_done <= 0;
                    sum_in_progress <= 0;
                end else if (!sum_done) begin
                    if (!sum_in_progress) begin
                        snapshot <= data_in;
                        // Start a fresh accumulation for every request.
                        sum_result <= data_in[0 +: DATA_WIDTH];
                        pointer <= (LENGTH > 1) ? 1 : 0;
                        sum_done <= (LENGTH == 1);
                        sum_in_progress <= (LENGTH > 1);
                    end else begin
                        sum_result <= sum_result + snapshot[pointer*DATA_WIDTH +: DATA_WIDTH];
                        if (pointer == LENGTH - 1) begin
                            sum_done <= 1'b1;
                            sum_in_progress <= 1'b0;
                        end else begin
                            pointer <= pointer + 1'b1;
                        end
                    end
                end
            end
        end else begin : gen_tree
            localparam STAGES = $clog2(LENGTH);
            localparam PADDED_LENGTH = 2**STAGES;
            // Every stage retains the full sum width, including carry bits.
            reg [DATA_OUT_WIDTH-1:0] tree [0:STAGES][0:PADDED_LENGTH-1];
            reg [STAGES:0] valid;
            integer stage, node;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    valid <= 0;
                    sum_result <= 0;
                    sum_done <= 0;
                    sum_in_progress <= 0;
                    for (stage = 0; stage <= STAGES; stage = stage + 1)
                        for (node = 0; node < (PADDED_LENGTH >> stage); node = node + 1)
                            tree[stage][node] <= 0;
                end else if (!sum_en) begin
                    valid <= 0;
                    sum_done <= 0;
                    sum_in_progress <= 0;
                end else if (!sum_done) begin
                    valid[0] <= !sum_in_progress;
                    if (!sum_in_progress) begin
                        sum_in_progress <= 1'b1;
                        for (node = 0; node < PADDED_LENGTH; node = node + 1) begin
                            if (node < LENGTH)
                                tree[0][node] <= data_in[node*DATA_WIDTH +: DATA_WIDTH];
                            else
                                tree[0][node] <= 0;
                        end
                    end
                    for (stage = 1; stage <= STAGES; stage = stage + 1) begin
                        valid[stage] <= valid[stage-1];
                        if (valid[stage-1])
                            for (node = 0; node < (PADDED_LENGTH >> stage); node = node + 1)
                                tree[stage][node] <= tree[stage-1][2*node] + tree[stage-1][2*node+1];
                    end
                    if (valid[STAGES]) begin
                        sum_result <= tree[STAGES][0];
                        sum_done <= 1'b1;
                        sum_in_progress <= 1'b0;
                    end
                end
            end
        end
    endgenerate
endmodule
