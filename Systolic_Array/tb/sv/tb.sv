`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 2025
// Module Name: tb
// Description: Comprehensive testbench for systolic array matrix multiplication.
//              Tests include:
//              1. Basic matrix multiplication with known values
//              2. Identity matrix multiplication
//              3. Random matrix multiplication
//              4. Edge cases (zeros, max values)
//
//////////////////////////////////////////////////////////////////////////////////

module tb();

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    parameter ARRAY_ROWS    = 4;            // PE rows
    parameter ARRAY_COLS    = 4;            // PE columns
    parameter K_DIM         = 4;            // Inner dimension
    parameter DATA_WIDTH    = 8;            // Activation width
    parameter WEIGHT_WIDTH  = 8;            // Weight width
    parameter ACC_WIDTH     = 32;           // Accumulator width
    parameter SIGNED_MATH   = 1;            // Signed arithmetic
    parameter INPUT_SKEW    = 1;            // Auto-skew

    parameter CLK_PERIOD    = 10;           // Clock period in ns
    parameter SIM_TIMEOUT   = 500000;       // Simulation timeout

    localparam MAX_SIGNED_VAL = (1 << (DATA_WIDTH-1)) - 1;
    localparam MIN_SIGNED_VAL = -(1 << (DATA_WIDTH-1));

    //--------------------------------------------------------------------------
    // DUT signals
    //--------------------------------------------------------------------------
    reg                                     clk;
    reg                                     rst_n;
    reg                                     start;
    wire                                    busy;
    wire                                    done;

    reg  [ARRAY_COLS*WEIGHT_WIDTH-1:0]      weight_data;
    reg                                     weight_valid;
    wire                                    weight_ready;

    reg  [ARRAY_ROWS*DATA_WIDTH-1:0]        act_data;
    reg                                     act_valid;
    wire                                    act_ready;

    wire [ARRAY_COLS*ACC_WIDTH-1:0]         result_data;
    wire                                    result_valid;
    reg                                     result_ready;

    //--------------------------------------------------------------------------
    // Test matrices
    //--------------------------------------------------------------------------
    // Matrix A: ARRAY_ROWS x K_DIM (activations)
    reg signed [DATA_WIDTH-1:0] matrix_a [ARRAY_ROWS-1:0][K_DIM-1:0];
    // Matrix B: K_DIM x ARRAY_COLS (weights) - stored transposed for easier loading
    reg signed [WEIGHT_WIDTH-1:0] matrix_b [K_DIM-1:0][ARRAY_COLS-1:0];
    // Expected result: ARRAY_ROWS x ARRAY_COLS
    reg signed [ACC_WIDTH-1:0] expected_c [ARRAY_ROWS-1:0][ARRAY_COLS-1:0];
    // Actual result from DUT
    reg signed [ACC_WIDTH-1:0] actual_c [ARRAY_ROWS-1:0][ARRAY_COLS-1:0];

    //--------------------------------------------------------------------------
    // Test variables
    //--------------------------------------------------------------------------
    integer i, j, k;
    integer err_cnt = 0;
    integer test_num = 0;
    integer result_row_cnt;
    string test_name;

    //--------------------------------------------------------------------------
    // DUT instantiation
    //--------------------------------------------------------------------------
    systolic_array_top #(
        .ARRAY_ROWS     (ARRAY_ROWS),
        .ARRAY_COLS     (ARRAY_COLS),
        .K_DIM          (K_DIM),
        .DATA_WIDTH     (DATA_WIDTH),
        .WEIGHT_WIDTH   (WEIGHT_WIDTH),
        .ACC_WIDTH      (ACC_WIDTH),
        .SIGNED_MATH    (SIGNED_MATH),
        .INPUT_SKEW     (INPUT_SKEW)
    ) DUT (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .busy           (busy),
        .done           (done),
        .weight_data    (weight_data),
        .weight_valid   (weight_valid),
        .weight_ready   (weight_ready),
        .act_data       (act_data),
        .act_valid      (act_valid),
        .act_ready      (act_ready),
        .result_data    (result_data),
        .result_valid   (result_valid),
        .result_ready   (result_ready)
    );

    //--------------------------------------------------------------------------
    // Clock generation
    //--------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //--------------------------------------------------------------------------
    // Compute expected result (golden model)
    //--------------------------------------------------------------------------
    task compute_expected_result();
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                expected_c[i][j] = 0;
                for (k = 0; k < K_DIM; k = k + 1) begin
                    expected_c[i][j] = expected_c[i][j] +
                        ($signed(matrix_a[i][k]) * $signed(matrix_b[k][j]));
                end
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Load weights into DUT
    //--------------------------------------------------------------------------
    task load_weights();
        integer kk, rr;
        $display("%0t Loading weights into systolic array...", $realtime);

        // Wait for weight_ready
        while (!weight_ready) @(posedge clk);

        // Load weights: iterate through K dimension, then rows
        for (kk = 0; kk < K_DIM; kk = kk + 1) begin
            for (rr = 0; rr < ARRAY_ROWS; rr = rr + 1) begin
                @(posedge clk);
                // Pack all columns for this row
                for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                    weight_data[(j+1)*WEIGHT_WIDTH-1 -: WEIGHT_WIDTH] = matrix_b[kk][j];
                end
                weight_valid = 1;
            end
        end

        @(posedge clk);
        weight_valid = 0;
        weight_data = 0;
        $display("%0t Weight loading complete", $realtime);
    endtask

    //--------------------------------------------------------------------------
    // Stream activations into DUT
    //--------------------------------------------------------------------------
    task stream_activations();
        integer kk;
        $display("%0t Streaming activations...", $realtime);

        // Wait for act_ready
        while (!act_ready) @(posedge clk);

        // Stream activations column by column (K dimension)
        for (kk = 0; kk < K_DIM; kk = kk + 1) begin
            @(posedge clk);
            // Pack all rows for this K column
            for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
                act_data[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = matrix_a[i][kk];
            end
            act_valid = 1;
        end

        @(posedge clk);
        act_valid = 0;
        act_data = 0;
        $display("%0t Activation streaming complete", $realtime);
    endtask

    //--------------------------------------------------------------------------
    // Collect results from DUT
    //--------------------------------------------------------------------------
    task collect_results();
        integer timeout_cnt;
        $display("%0t Collecting results...", $realtime);

        result_ready = 1;
        result_row_cnt = 0;
        timeout_cnt = 0;

        // Wait for results
        while (!done && timeout_cnt < 1000) begin
            @(posedge clk);
            timeout_cnt = timeout_cnt + 1;

            if (result_valid) begin
                // Unpack result row
                for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                    actual_c[result_row_cnt][j] = $signed(result_data[(j+1)*ACC_WIDTH-1 -: ACC_WIDTH]);
                end
                result_row_cnt = result_row_cnt + 1;
                $display("%0t Received result row %0d", $realtime, result_row_cnt);
            end
        end

        result_ready = 0;
        $display("%0t Result collection complete", $realtime);
    endtask

    //--------------------------------------------------------------------------
    // Compare results
    //--------------------------------------------------------------------------
    task compare_results();
        integer local_err = 0;
        $display("\n=== Result Comparison ===");

        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                if (actual_c[i][j] !== expected_c[i][j]) begin
                    $display("ERROR: C[%0d][%0d] mismatch - Expected: %0d, Actual: %0d",
                             i, j, expected_c[i][j], actual_c[i][j]);
                    local_err = local_err + 1;
                    err_cnt = err_cnt + 1;
                end
            end
        end

        if (local_err == 0) begin
            $display("Test %0d (%s): PASSED", test_num, test_name);
        end else begin
            $display("Test %0d (%s): FAILED with %0d errors", test_num, test_name, local_err);
        end
    endtask

    //--------------------------------------------------------------------------
    // Print matrices
    //--------------------------------------------------------------------------
    task print_matrices();
        $display("\nMatrix A (%0d x %0d):", ARRAY_ROWS, K_DIM);
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            $write("  [");
            for (k = 0; k < K_DIM; k = k + 1) begin
                $write("%4d ", matrix_a[i][k]);
            end
            $display("]");
        end

        $display("\nMatrix B (%0d x %0d):", K_DIM, ARRAY_COLS);
        for (k = 0; k < K_DIM; k = k + 1) begin
            $write("  [");
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                $write("%4d ", matrix_b[k][j]);
            end
            $display("]");
        end

        $display("\nExpected C (%0d x %0d):", ARRAY_ROWS, ARRAY_COLS);
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            $write("  [");
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                $write("%6d ", expected_c[i][j]);
            end
            $display("]");
        end
    endtask

    //--------------------------------------------------------------------------
    // Run single test
    //--------------------------------------------------------------------------
    task run_single_test();
        compute_expected_result();
        print_matrices();

        // Start computation
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for busy
        while (!busy) @(posedge clk);

        // Load weights and stream activations in parallel (sequentially in FSM)
        fork
            load_weights();
            stream_activations();
            collect_results();
        join

        // Wait for done
        while (!done) @(posedge clk);

        compare_results();

        // Gap between tests
        repeat(10) @(posedge clk);
    endtask

    //--------------------------------------------------------------------------
    // Test 1: Simple known values
    //--------------------------------------------------------------------------
    task test_simple_values();
        test_num = test_num + 1;
        test_name = "Simple Known Values";
        $display("\n========================================");
        $display("Test %0d: %s", test_num, test_name);
        $display("========================================");

        // Initialize A with simple values [1,2,3,4; 5,6,7,8; ...]
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                matrix_a[i][k] = i * K_DIM + k + 1;
            end
        end

        // Initialize B with simple values [1,2,3,4; 5,6,7,8; ...]
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                matrix_b[k][j] = k * ARRAY_COLS + j + 1;
            end
        end

        run_single_test();
    endtask

    //--------------------------------------------------------------------------
    // Test 2: Identity matrix multiplication
    //--------------------------------------------------------------------------
    task test_identity_matrix();
        test_num = test_num + 1;
        test_name = "Identity Matrix";
        $display("\n========================================");
        $display("Test %0d: %s", test_num, test_name);
        $display("========================================");

        // A = random values
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                matrix_a[i][k] = $urandom_range(1, 10);
            end
        end

        // B = identity (assuming square matrix)
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                matrix_b[k][j] = (k == j) ? 1 : 0;
            end
        end

        run_single_test();
    endtask

    //--------------------------------------------------------------------------
    // Test 3: Random matrix multiplication
    //--------------------------------------------------------------------------
    task test_random_matrices();
        test_num = test_num + 1;
        test_name = "Random Matrices";
        $display("\n========================================");
        $display("Test %0d: %s", test_num, test_name);
        $display("========================================");

        // Random A
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                if (SIGNED_MATH)
                    matrix_a[i][k] = $random % (MAX_SIGNED_VAL + 1);
                else
                    matrix_a[i][k] = $urandom_range(0, (1 << DATA_WIDTH) - 1);
            end
        end

        // Random B
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                if (SIGNED_MATH)
                    matrix_b[k][j] = $random % (MAX_SIGNED_VAL + 1);
                else
                    matrix_b[k][j] = $urandom_range(0, (1 << WEIGHT_WIDTH) - 1);
            end
        end

        run_single_test();
    endtask

    //--------------------------------------------------------------------------
    // Test 4: Zero matrix
    //--------------------------------------------------------------------------
    task test_zero_matrix();
        test_num = test_num + 1;
        test_name = "Zero Matrix";
        $display("\n========================================");
        $display("Test %0d: %s", test_num, test_name);
        $display("========================================");

        // A = all zeros
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                matrix_a[i][k] = 0;
            end
        end

        // B = random
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                matrix_b[k][j] = $urandom_range(1, 10);
            end
        end

        run_single_test();
    endtask

    //--------------------------------------------------------------------------
    // Test 5: Negative values (signed)
    //--------------------------------------------------------------------------
    task test_signed_values();
        test_num = test_num + 1;
        test_name = "Signed Values";
        $display("\n========================================");
        $display("Test %0d: %s", test_num, test_name);
        $display("========================================");

        // A with positive and negative values
        for (i = 0; i < ARRAY_ROWS; i = i + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                matrix_a[i][k] = ((i + k) % 2 == 0) ? (k + 1) : -(k + 1);
            end
        end

        // B with positive and negative values
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (j = 0; j < ARRAY_COLS; j = j + 1) begin
                matrix_b[k][j] = ((k + j) % 2 == 0) ? (j + 1) : -(j + 1);
            end
        end

        run_single_test();
    endtask

    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    initial begin
        string vcdfile;
        int vcdlevel;
        int seed;

        // Initialize signals
        rst_n = 0;
        start = 0;
        weight_data = 0;
        weight_valid = 0;
        act_data = 0;
        act_valid = 0;
        result_ready = 0;

        // VCD dump setup
        if ($value$plusargs("VCDFILE=%s", vcdfile))
            $dumpfile(vcdfile);
        if ($value$plusargs("VCDLEVEL=%d", vcdlevel))
            $dumpvars(vcdlevel, tb);
        if ($value$plusargs("SEED=%d", seed)) begin
            $urandom(seed);
            $display("Seed = %d", seed);
        end

        $display("\n");
        $display("============================================");
        $display("   Systolic Array Testbench");
        $display("============================================");
        $display("Array Size:    %0d x %0d", ARRAY_ROWS, ARRAY_COLS);
        $display("K Dimension:   %0d", K_DIM);
        $display("Data Width:    %0d bits", DATA_WIDTH);
        $display("Weight Width:  %0d bits", WEIGHT_WIDTH);
        $display("Acc Width:     %0d bits", ACC_WIDTH);
        $display("Signed Math:   %s", SIGNED_MATH ? "Yes" : "No");
        $display("============================================\n");

        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        // Run tests
        test_simple_values();
        test_identity_matrix();
        test_random_matrices();
        test_zero_matrix();

        if (SIGNED_MATH) begin
            test_signed_values();
        end

        // Multiple random tests
        repeat(3) begin
            test_random_matrices();
        end

        // Summary
        $display("\n============================================");
        $display("   Test Summary");
        $display("============================================");
        $display("Total Tests: %0d", test_num);
        if (err_cnt == 0) begin
            $display("Result: ALL TESTS PASSED");
        end else begin
            $display("Result: FAILED");
            $display("Total Errors: %0d", err_cnt);
        end
        $display("============================================\n");

        #100;
        $finish;
    end

    //--------------------------------------------------------------------------
    // Timeout watchdog
    //--------------------------------------------------------------------------
    initial begin
        #(SIM_TIMEOUT);
        $display("\n%0t ERROR: Simulation timeout!", $realtime);
        $display("TEST FAILED - SIM TIMEOUT\n");
        $finish;
    end

endmodule
