`timescale 1ns / 1ps
// Weight-stationary array core. Physical rows are reduction lanes of a K tile.
// Preload B[r,c], then inject A[m,r] on lane r at enabled step m+r.
// Activations move right; partial sums move down. Column c's dot product
// for output row m appears after enabled step ARRAY_ROWS-1+m+c.
// clear_acc clears both data pipelines; stored weights remain unchanged.

module systolic_array #(
    parameter ARRAY_ROWS     = 4,                   // Number of reduction lanes per K tile
    parameter ARRAY_COLS     = 4,                   // Number of PE columns (N dimension tile)
    parameter DATA_WIDTH     = 8,                   // Activation data width
    parameter WEIGHT_WIDTH   = 8,                   // Weight data width
    parameter ACC_WIDTH      = 32,                  // Accumulator width
    parameter SIGNED_MATH    = 1                    // 1 = signed, 0 = unsigned
)(
    input  wire                                     clk,
    input  wire                                     rst_n,

    // Control signals
    input  wire                                     enable,             // Global enable
    input  wire                                     clear_acc,          // Clear all accumulators
    input  wire [ARRAY_COLS-1:0]                    load_weight,        // Load weight per column
    input  wire [((ARRAY_ROWS > 1) ? $clog2(ARRAY_ROWS) : 1)-1:0] weight_row_sel,

    // Activation inputs (left side) - one per row
    input  wire [ARRAY_ROWS*DATA_WIDTH-1:0]         act_in,             // Packed activation inputs

    // Weight inputs (top side) - one per column during loading
    input  wire [ARRAY_COLS*WEIGHT_WIDTH-1:0]       weight_in,          // Packed weight inputs

    // Partial sum inputs (top side) - normally zero, for cascading arrays
    input  wire [ARRAY_COLS*ACC_WIDTH-1:0]          psum_in,            // Packed psum inputs (top)

    // Partial sum outputs (bottom side) - computation results
    output wire [ARRAY_COLS*ACC_WIDTH-1:0]          psum_out,           // Packed psum outputs (bottom)

    // Activation outputs (right side) - for cascading arrays
    output wire [ARRAY_ROWS*DATA_WIDTH-1:0]         act_out             // Packed activation outputs
);

    //--------------------------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------------------------
    localparam ROW_SEL_WIDTH = $clog2(ARRAY_ROWS) > 0 ? $clog2(ARRAY_ROWS) : 1;

    //--------------------------------------------------------------------------
    // Internal interconnect wires
    //--------------------------------------------------------------------------
    // Horizontal activation wires (left to right through PE columns)
    // act_h[row][col] connects PE[row][col-1].act_out to PE[row][col].act_in
    wire [DATA_WIDTH-1:0] act_h [ARRAY_ROWS-1:0][ARRAY_COLS:0];

    // Vertical partial sum wires (top to bottom through PE rows)
    // psum_v[row][col] connects PE[row-1][col].psum_out to PE[row][col].psum_in
    wire [ACC_WIDTH-1:0] psum_v [ARRAY_ROWS:0][ARRAY_COLS-1:0];

    // Weight load enable per PE
    wire load_weight_pe [ARRAY_ROWS-1:0][ARRAY_COLS-1:0];

    //--------------------------------------------------------------------------
    // Weight input unpacking
    //--------------------------------------------------------------------------
    wire [WEIGHT_WIDTH-1:0] weight_col [ARRAY_COLS-1:0];

    genvar c;
    generate
        for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_weight_unpack
            assign weight_col[c] = weight_in[(c+1)*WEIGHT_WIDTH-1 -: WEIGHT_WIDTH];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Connect activation inputs (left edge)
    //--------------------------------------------------------------------------
    genvar r;
    generate
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin : gen_act_in_connect
            assign act_h[r][0] = act_in[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Connect partial sum inputs (top edge)
    //--------------------------------------------------------------------------
    generate
        for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_psum_in_connect
            assign psum_v[0][c] = psum_in[(c+1)*ACC_WIDTH-1 -: ACC_WIDTH];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Generate PE array with interconnections
    //--------------------------------------------------------------------------
    generate
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin : gen_row
            for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_col

                // Weight load enable: column selected AND row matches
                assign load_weight_pe[r][c] = load_weight[c] && (weight_row_sel == r[ROW_SEL_WIDTH-1:0]);

                // Instantiate Processing Element
                pe #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .WEIGHT_WIDTH   (WEIGHT_WIDTH),
                    .ACC_WIDTH      (ACC_WIDTH),
                    .SIGNED_MATH    (SIGNED_MATH)
                ) pe_inst (
                    .clk            (clk),
                    .rst_n          (rst_n),

                    // Control
                    .enable         (enable),
                    .clear_acc      (clear_acc),
                    .load_weight    (load_weight_pe[r][c]),

                    // Data flow
                    .act_in         (act_h[r][c]),
                    .weight_in      (weight_col[c]),
                    .psum_in        (psum_v[r][c]),
                    .act_out        (act_h[r][c+1]),
                    .psum_out       (psum_v[r+1][c]),

                    // Debug
                    .weight_stored  ()  // Not connected at this level
                );

            end
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Connect activation outputs (right edge)
    //--------------------------------------------------------------------------
    generate
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin : gen_act_out_connect
            assign act_out[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH] = act_h[r][ARRAY_COLS];
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Connect partial sum outputs (bottom edge)
    //--------------------------------------------------------------------------
    generate
        for (c = 0; c < ARRAY_COLS; c = c + 1) begin : gen_psum_out_connect
            assign psum_out[(c+1)*ACC_WIDTH-1 -: ACC_WIDTH] = psum_v[ARRAY_ROWS][c];
        end
    endgenerate

endmodule
