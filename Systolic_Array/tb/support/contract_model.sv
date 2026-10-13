`timescale 1ns / 1ps
`ifndef SELFTEST_FAULT
`define SELFTEST_FAULT 0
`endif
// Verification fixture only: a behavioral implementation of the existing wire contract.
// Faults: 1=no rows, 2=missing row, 3=extra row, 4=wrong data, 5=hang, 6=unstable stall.
module systolic_array_top #(
    parameter ARRAY_ROWS = 4, ARRAY_COLS = 4, K_DIM = 4,
    parameter DATA_WIDTH = 8, WEIGHT_WIDTH = 8, ACC_WIDTH = 32,
    parameter SIGNED_MATH = 1, INPUT_SKEW = 1
) (
    input wire clk, rst_n, start,
    output wire busy, done,
    input wire [ARRAY_COLS*WEIGHT_WIDTH-1:0] weight_data,
    input wire weight_valid,
    output wire weight_ready,
    input wire [ARRAY_ROWS*DATA_WIDTH-1:0] act_data,
    input wire act_valid,
    output wire act_ready,
    output reg [ARRAY_COLS*ACC_WIDTH-1:0] result_data,
    output wire result_valid,
    input wire result_ready
);
    localparam IDLE = 0, LOAD = 1, COMPUTE = 2, OUTPUT = 3, DONE = 4;
    localparam FAULT = `SELFTEST_FAULT;
    localparam OUTPUT_ROWS = ARRAY_ROWS + (FAULT == 3) - (FAULT == 2);
    localparam ACT_BEATS = INPUT_SKEW ? K_DIM : K_DIM + ARRAY_ROWS - 1;
    integer state = IDLE;
    integer weight_count, act_count, output_count, stall_ticks;
    integer r, c, k;
    reg [DATA_WIDTH-1:0] a [0:ARRAY_ROWS-1][0:K_DIM-1];
    reg [WEIGHT_WIDTH-1:0] b [0:K_DIM-1][0:ARRAY_COLS-1];
    reg [ACC_WIDTH-1:0] results [0:ARRAY_ROWS-1][0:ARRAY_COLS-1];
    reg [ACC_WIDTH-1:0] total;
    reg signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] product;

    assign busy = state != IDLE && state != DONE;
    assign done = state == DONE;
    assign weight_ready = state == LOAD;
    assign act_ready = state == COMPUTE;
    assign result_valid = state == OUTPUT && FAULT != 5;

    always @(*) begin
        result_data = 0;
        if (state == OUTPUT && output_count < ARRAY_ROWS)
            for (integer col = 0; col < ARRAY_COLS; col = col + 1)
                result_data[col*ACC_WIDTH +: ACC_WIDTH] = results[output_count][col];
        if (FAULT == 4) result_data = result_data ^ 1'b1;
        if (FAULT == 6) result_data = result_data ^ stall_ticks;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            weight_count <= 0;
            act_count <= 0;
            output_count <= 0;
            stall_ticks <= 0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    state <= LOAD;
                    weight_count <= 0;
                    act_count <= 0;
                    output_count <= 0;
                    stall_ticks <= 0;
                end
                LOAD: if (weight_valid && weight_ready) begin
                    for (c = 0; c < ARRAY_COLS; c = c + 1)
                        b[weight_count / ARRAY_ROWS][c] = weight_data[c*WEIGHT_WIDTH +: WEIGHT_WIDTH];
                    weight_count <= weight_count + 1;
                    if (weight_count == K_DIM*ARRAY_ROWS - 1) state <= COMPUTE;
                end
                COMPUTE: if (act_valid && act_ready) begin
                    for (r = 0; r < ARRAY_ROWS; r = r + 1) begin
                        if (INPUT_SKEW)
                            a[r][act_count] = act_data[r*DATA_WIDTH +: DATA_WIDTH];
                        else if (act_count >= r && act_count < K_DIM + r)
                            a[r][act_count-r] = act_data[r*DATA_WIDTH +: DATA_WIDTH];
                    end
                    act_count <= act_count + 1;
                    if (act_count == ACT_BEATS - 1) begin
                        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin
                            for (c = 0; c < ARRAY_COLS; c = c + 1) begin
                                total = 0;
                                for (k = 0; k < K_DIM; k = k + 1) begin
                                    if (SIGNED_MATH) begin
                                        product = $signed(a[r][k]) * $signed(b[k][c]);
                                        total = total + {{(ACC_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){product[DATA_WIDTH+WEIGHT_WIDTH-1]}}, product};
                                    end else
                                        total = total + $unsigned(a[r][k]) * $unsigned(b[k][c]);
                                end
                                results[r][c] = total;
                            end
                        end
                        state <= (FAULT == 1 || OUTPUT_ROWS == 0) ? DONE : OUTPUT;
                    end
                end
                OUTPUT: begin
                    if (!result_ready) stall_ticks <= stall_ticks + 1;
                    if (result_valid && result_ready) begin
                        output_count <= output_count + 1;
                        if (output_count == OUTPUT_ROWS - 1) state <= DONE;
                    end
                end
                DONE: state <= IDLE;
            endcase
        end
    end
endmodule
