`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: pe (Processing Element)
// Description: Single processing element for systolic array matrix multiplication.
//              Implements weight-stationary dataflow with multiply-accumulate.
//
// Dataflow:
//   - Weight is pre-loaded and remains stationary during computation
//   - Activation flows left-to-right (horizontal propagation)
//   - Partial sum flows top-to-bottom (vertical propagation)
//   - Each PE computes: psum_out = psum_in + (weight * activation)
//
// Operation Modes:
//   - IDLE:    PE is inactive, passes data through
//   - LOAD:    Load weight into weight register
//   - COMPUTE: Perform MAC operation and propagate data
//   - OUTPUT:  Output accumulated result (when configured for output-stationary)
//
//////////////////////////////////////////////////////////////////////////////////

module pe #(
    parameter DATA_WIDTH     = 8,                           // Input data bit width
    parameter WEIGHT_WIDTH   = 8,                           // Weight bit width
    parameter ACC_WIDTH      = 32,                          // Accumulator bit width (must handle full precision)
    parameter SIGNED_MATH    = 1                            // 1 = signed, 0 = unsigned arithmetic
)(
    input  wire                         clk,
    input  wire                         rst_n,              // Active-low reset

    // Control signals
    input  wire                         enable,             // Enable PE operation
    input  wire                         clear_acc,          // Clear accumulator
    input  wire                         load_weight,        // Load weight register

    // Data inputs
    input  wire [DATA_WIDTH-1:0]        act_in,             // Activation input (from left)
    input  wire [WEIGHT_WIDTH-1:0]      weight_in,          // Weight input for loading
    input  wire [ACC_WIDTH-1:0]         psum_in,            // Partial sum input (from top)

    // Data outputs
    output reg  [DATA_WIDTH-1:0]        act_out,            // Activation output (to right)
    output reg  [ACC_WIDTH-1:0]         psum_out,           // Partial sum output (to bottom)

    // Status
    output wire [WEIGHT_WIDTH-1:0]      weight_stored       // Current stored weight (for debug)
);

    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    reg  [WEIGHT_WIDTH-1:0]             weight_reg;         // Weight register (stationary)
    wire [DATA_WIDTH+WEIGHT_WIDTH-1:0]  product;            // Multiplication result
    wire [ACC_WIDTH-1:0]                mac_result;         // MAC result

    //--------------------------------------------------------------------------
    // Weight register - loads and holds weight value
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= {WEIGHT_WIDTH{1'b0}};
        end else if (load_weight) begin
            weight_reg <= weight_in;
        end
    end

    assign weight_stored = weight_reg;

    //--------------------------------------------------------------------------
    // Multiply-Accumulate (MAC) computation
    //--------------------------------------------------------------------------
    generate
        if (SIGNED_MATH == 1) begin : gen_signed_mac
            // Signed multiplication
            wire signed [DATA_WIDTH-1:0]   act_signed   = $signed(act_in);
            wire signed [WEIGHT_WIDTH-1:0] weight_signed = $signed(weight_reg);
            wire signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] product_signed;

            assign product_signed = act_signed * weight_signed;
            assign product = product_signed;

            // Sign-extend product to accumulator width and add partial sum
            wire signed [ACC_WIDTH-1:0] product_extended = {{(ACC_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){product_signed[DATA_WIDTH+WEIGHT_WIDTH-1]}}, product_signed};
            wire signed [ACC_WIDTH-1:0] psum_signed = $signed(psum_in);

            assign mac_result = product_extended + psum_signed;
        end else begin : gen_unsigned_mac
            // Unsigned multiplication
            assign product = act_in * weight_reg;

            // Zero-extend product to accumulator width and add partial sum
            wire [ACC_WIDTH-1:0] product_extended = {{(ACC_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){1'b0}}, product};

            assign mac_result = product_extended + psum_in;
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Output registers - pipeline stage for data propagation
    //--------------------------------------------------------------------------

    // Activation propagation (left to right) - 1 cycle delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out <= {DATA_WIDTH{1'b0}};
        end else if (enable) begin
            act_out <= act_in;
        end
    end

    // Partial sum propagation (top to bottom) - MAC result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psum_out <= {ACC_WIDTH{1'b0}};
        end else if (clear_acc) begin
            psum_out <= {ACC_WIDTH{1'b0}};
        end else if (enable) begin
            psum_out <= mac_result;
        end
    end

endmodule
