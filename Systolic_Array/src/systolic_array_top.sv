`timescale 1ns / 1ps
// Buffered wrapper around the weight-stationary PE array.
// A: ARRAY_ROWS x K_DIM; B: K_DIM x ARRAY_COLS.
// The existing K_DIM * ARRAY_ROWS weight-transfer schedule is preserved.
// Internal PE rows represent a tile of K, not output matrix rows.
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
    output wire [ARRAY_COLS*ACC_WIDTH-1:0] result_data,
    output wire result_valid,
    input wire result_ready
);
    localparam ROW_WIDTH = (ARRAY_ROWS > 1) ? $clog2(ARRAY_ROWS) : 1;
    localparam K_WIDTH = (K_DIM > 1) ? $clog2(K_DIM) : 1;
    // In external-skew mode, lane r's A[r,k] arrives on accepted beat k+r.
    localparam ACT_BEATS = INPUT_SKEW ? K_DIM : K_DIM + ARRAY_ROWS - 1;
    localparam ACT_COUNT_WIDTH = (ACT_BEATS > 1) ? $clog2(ACT_BEATS) : 1;
    localparam RUN_CYCLES = 2*ARRAY_ROWS + ARRAY_COLS - 1;
    localparam RUN_WIDTH = (RUN_CYCLES > 1) ? $clog2(RUN_CYCLES) : 1;
    localparam [2:0] IDLE = 3'd0, LOAD_WEIGHT = 3'd1, LOAD_ACT = 3'd2,
                     LOAD_TILE = 3'd3, CLEAR_TILE = 3'd4, RUN_TILE = 3'd5,
                     OUTPUT_ROWS = 3'd6, COMPLETE = 3'd7;

    reg [2:0] state;
    reg [ROW_WIDTH-1:0] weight_repeat, tile_row, output_row;
    reg [K_WIDTH-1:0] weight_k, tile_base;
    reg [ACT_COUNT_WIDTH-1:0] act_count;
    reg [RUN_WIDTH-1:0] run_count;
    reg [ARRAY_COLS*WEIGHT_WIDTH-1:0] weights [0:K_DIM-1];
    reg [DATA_WIDTH-1:0] activations [0:ARRAY_ROWS-1][0:K_DIM-1];
    reg [ACC_WIDTH-1:0] results [0:ARRAY_ROWS-1][0:ARRAY_COLS-1];

    wire sa_enable = (state == RUN_TILE);
    wire sa_clear = (state == CLEAR_TILE);
    wire [ARRAY_COLS-1:0] sa_load = {ARRAY_COLS{state == LOAD_TILE}};
    reg [ARRAY_ROWS*DATA_WIDTH-1:0] sa_act;
    reg [ARRAY_COLS*WEIGHT_WIDTH-1:0] sa_weight;
    wire [ARRAY_COLS*ACC_WIDTH-1:0] sa_psum;

    // Transpose buffered A into reduction lanes, skewed by the physical PE row.
    // Pad the unused reduction lanes in the last tile with zero.
    integer lane;
    always @(*) begin
        sa_act = 0;
        sa_weight = 0;
        if (state == LOAD_TILE && tile_base + tile_row < K_DIM)
            sa_weight = weights[tile_base + tile_row];
        for (lane = 0; lane < ARRAY_ROWS; lane = lane + 1) begin
            if (state == RUN_TILE && run_count >= lane &&
                run_count < lane + ARRAY_ROWS && tile_base + lane < K_DIM)
                sa_act[lane*DATA_WIDTH +: DATA_WIDTH] =
                    activations[run_count-lane][tile_base+lane];
        end
    end

    systolic_array #(
        .ARRAY_ROWS(ARRAY_ROWS), .ARRAY_COLS(ARRAY_COLS),
        .DATA_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH), .SIGNED_MATH(SIGNED_MATH)
    ) u_systolic_array (
        .clk(clk), .rst_n(rst_n), .enable(sa_enable), .clear_acc(sa_clear),
        .load_weight(sa_load), .weight_row_sel(tile_row),
        .act_in(sa_act), .weight_in(sa_weight),
        .psum_in({ARRAY_COLS*ACC_WIDTH{1'b0}}), .psum_out(sa_psum), .act_out()
    );

    assign busy = rst_n && state != IDLE && state != COMPLETE;
    assign done = rst_n && state == COMPLETE;
    assign weight_ready = rst_n && state == LOAD_WEIGHT;
    assign act_ready = rst_n && state == LOAD_ACT;
    assign result_valid = rst_n && state == OUTPUT_ROWS;

    genvar col;
    generate
        for (col = 0; col < ARRAY_COLS; col = col + 1) begin : gen_result
            assign result_data[col*ACC_WIDTH +: ACC_WIDTH] =
                result_valid ? results[output_row][col] : {ACC_WIDTH{1'b0}};
        end
        if (ARRAY_ROWS < 1 || ARRAY_COLS < 1 || K_DIM < 1 ||
            DATA_WIDTH < 1 || WEIGHT_WIDTH < 1 || ACC_WIDTH < DATA_WIDTH + WEIGHT_WIDTH ||
            (SIGNED_MATH != 0 && SIGNED_MATH != 1) ||
            (INPUT_SKEW != 0 && INPUT_SKEW != 1)) begin : gen_invalid_parameters
            initial $fatal(1, "Invalid systolic_array_top parameters");
        end
    endgenerate

    integer row, column;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            weight_repeat <= 0;
            weight_k <= 0;
            act_count <= 0;
            tile_base <= 0;
            tile_row <= 0;
            run_count <= 0;
            output_row <= 0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    weight_repeat <= 0;
                    weight_k <= 0;
                    act_count <= 0;
                    tile_base <= 0;
                    tile_row <= 0;
                    run_count <= 0;
                    output_row <= 0;
                    for (row = 0; row < ARRAY_ROWS; row = row + 1)
                        for (column = 0; column < ARRAY_COLS; column = column + 1)
                            results[row][column] <= 0;
                    state <= LOAD_WEIGHT;
                end
                LOAD_WEIGHT: if (weight_valid && weight_ready) begin
                    weights[weight_k] <= weight_data;
                    if (weight_repeat == ARRAY_ROWS - 1) begin
                        weight_repeat <= 0;
                        if (weight_k == K_DIM - 1) begin
                            act_count <= 0;
                            state <= LOAD_ACT;
                        end else begin
                            weight_k <= weight_k + 1'b1;
                        end
                    end else begin
                        weight_repeat <= weight_repeat + 1'b1;
                    end
                end
                LOAD_ACT: if (act_valid && act_ready) begin
                    for (row = 0; row < ARRAY_ROWS; row = row + 1) begin
                        if (INPUT_SKEW)
                            activations[row][act_count] <= act_data[row*DATA_WIDTH +: DATA_WIDTH];
                        else if (act_count >= row && act_count < K_DIM + row)
                            activations[row][act_count-row] <= act_data[row*DATA_WIDTH +: DATA_WIDTH];
                    end
                    if (act_count == ACT_BEATS - 1) begin
                        tile_base <= 0;
                        tile_row <= 0;
                        state <= LOAD_TILE;
                    end else begin
                        act_count <= act_count + 1'b1;
                    end
                end
                LOAD_TILE: begin
                    // The selected PE row loads on this edge, without delayed controls.
                    if (tile_row == ARRAY_ROWS - 1)
                        state <= CLEAR_TILE;
                    else
                        tile_row <= tile_row + 1'b1;
                end
                CLEAR_TILE: begin
                    run_count <= 0;
                    state <= RUN_TILE;
                end
                RUN_TILE: begin
                    // Column c's result row m is captured at step ARRAY_ROWS+m+c.
                    // Add partial results from successive K tiles modulo ACC_WIDTH.
                    for (column = 0; column < ARRAY_COLS; column = column + 1) begin
                        if (run_count >= ARRAY_ROWS + column &&
                            run_count < 2*ARRAY_ROWS + column)
                            results[run_count-ARRAY_ROWS-column][column] <=
                                results[run_count-ARRAY_ROWS-column][column] +
                                sa_psum[column*ACC_WIDTH +: ACC_WIDTH];
                    end
                    if (run_count == RUN_CYCLES - 1) begin
                        if (tile_base + ARRAY_ROWS < K_DIM) begin
                            tile_base <= tile_base + ARRAY_ROWS;
                            tile_row <= 0;
                            state <= LOAD_TILE;
                        end else begin
                            output_row <= 0;
                            state <= OUTPUT_ROWS;
                        end
                    end else begin
                        run_count <= run_count + 1'b1;
                    end
                end
                OUTPUT_ROWS: if (result_valid && result_ready) begin
                    if (output_row == ARRAY_ROWS - 1)
                        state <= COMPLETE;
                    else
                        output_row <= output_row + 1'b1;
                end
                COMPLETE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
