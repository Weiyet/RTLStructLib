`timescale 1ns / 1ps
// Drive inputs at negedge; check transfers at posedge before NBA updates.
module tb;
    parameter ARRAY_ROWS = 4;
    parameter ARRAY_COLS = 4;
    parameter K_DIM = 4;
    parameter DATA_WIDTH = 8;
    parameter WEIGHT_WIDTH = 8;
    parameter ACC_WIDTH = 32;
    parameter SIGNED_MATH = 1;
    parameter INPUT_SKEW = 1;
    parameter CLK_PERIOD = 10;
    parameter TB_TIMEOUT_CYCLES = 1000;
    parameter SIM_TIMEOUT = 1000000;

    reg clk = 0;
    reg rst_n = 0, start = 0;
    reg weight_valid = 0, act_valid = 0, result_ready = 0;
    reg [ARRAY_COLS*WEIGHT_WIDTH-1:0] weight_data = 0;
    reg [ARRAY_ROWS*DATA_WIDTH-1:0] act_data = 0;
    wire busy, done, weight_ready, act_ready, result_valid;
    wire [ARRAY_COLS*ACC_WIDTH-1:0] result_data;
    reg [DATA_WIDTH-1:0] matrix_a [0:ARRAY_ROWS-1][0:K_DIM-1];
    reg [WEIGHT_WIDTH-1:0] matrix_b [0:K_DIM-1][0:ARRAY_COLS-1];
    reg [ACC_WIDTH-1:0] expected_c [0:ARRAY_ROWS-1][0:ARRAY_COLS-1];
    integer test_num = 0;
    reg [255:0] selected_test = "all";

    systolic_array_top #(
        .ARRAY_ROWS(ARRAY_ROWS), .ARRAY_COLS(ARRAY_COLS), .K_DIM(K_DIM),
        .DATA_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACC_WIDTH(ACC_WIDTH), .SIGNED_MATH(SIGNED_MATH), .INPUT_SKEW(INPUT_SKEW)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .busy(busy), .done(done),
        .weight_data(weight_data), .weight_valid(weight_valid), .weight_ready(weight_ready),
        .act_data(act_data), .act_valid(act_valid), .act_ready(act_ready),
        .result_data(result_data), .result_valid(result_valid), .result_ready(result_ready)
    );

    always #(CLK_PERIOD/2.0) clk = ~clk;

    task automatic reset_dut;
        @(negedge clk);
        rst_n = 0;
        start = 0;
        weight_valid = 0;
        act_valid = 0;
        result_ready = 0;
        weight_data = 0;
        act_data = 0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        if ({busy, done, result_valid, weight_ready, act_ready} !== 5'b0)
            $fatal(1, "Control output active during reset");
        rst_n = 1;
        repeat (2) begin
            @(negedge clk);
            if ({busy, done, result_valid} !== 3'b0)
                $fatal(1, "Stale control/result after reset");
        end
    endtask

    task automatic begin_job;
        if (busy !== 1'b0) $fatal(1, "DUT busy before start");
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
    endtask

    task automatic fill_matrices(input [255:0] kind);
        integer r, c, k, bit_idx;
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin
            for (k = 0; k < K_DIM; k = k + 1) begin
                for (bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx = bit_idx + 1)
                    matrix_a[r][k][bit_idx] = $urandom_range(0, 1);
                case (kind)
                    "simple": matrix_a[r][k] = r*K_DIM + k + 1;
                    "zero": matrix_a[r][k] = 0;
                    "signed": matrix_a[r][k] = ((r+k)%2) ? -(k+1) : k+1;
                    "limits": begin
                        case ((r+k)%4)
                            0: matrix_a[r][k] = SIGNED_MATH ? {1'b1, {(DATA_WIDTH-1){1'b0}}} : {DATA_WIDTH{1'b1}};
                            1: matrix_a[r][k] = SIGNED_MATH ? {1'b0, {(DATA_WIDTH-1){1'b1}}} : 1;
                            2: matrix_a[r][k] = SIGNED_MATH ? {DATA_WIDTH{1'b1}} : 0;
                            3: matrix_a[r][k] = SIGNED_MATH ? 0 : {DATA_WIDTH{1'b1}} - 1'b1;
                        endcase
                    end
                endcase
            end
        end
        for (k = 0; k < K_DIM; k = k + 1) begin
            for (c = 0; c < ARRAY_COLS; c = c + 1) begin
                for (bit_idx = 0; bit_idx < WEIGHT_WIDTH; bit_idx = bit_idx + 1)
                    matrix_b[k][c][bit_idx] = $urandom_range(0, 1);
                case (kind)
                    "simple": matrix_b[k][c] = k*ARRAY_COLS + c + 1;
                    "identity": matrix_b[k][c] = (k == c);
                    "signed": matrix_b[k][c] = ((k+c)%2) ? -(c+1) : c+1;
                    "limits": begin
                        case ((k+c)%4)
                            0: matrix_b[k][c] = SIGNED_MATH ? {1'b1, {(WEIGHT_WIDTH-1){1'b0}}} : {WEIGHT_WIDTH{1'b1}};
                            1: matrix_b[k][c] = SIGNED_MATH ? {1'b0, {(WEIGHT_WIDTH-1){1'b1}}} : 1;
                            2: matrix_b[k][c] = SIGNED_MATH ? {WEIGHT_WIDTH{1'b1}} : 0;
                            3: matrix_b[k][c] = SIGNED_MATH ? 0 : {WEIGHT_WIDTH{1'b1}} - 1'b1;
                        endcase
                    end
                endcase
            end
        end
    endtask

    task automatic compute_expected;
        integer r, c, k;
        reg [ACC_WIDTH-1:0] total;
        reg signed [DATA_WIDTH+WEIGHT_WIDTH-1:0] product;
        for (r = 0; r < ARRAY_ROWS; r = r + 1) begin
            for (c = 0; c < ARRAY_COLS; c = c + 1) begin
                total = 0;
                for (k = 0; k < K_DIM; k = k + 1) begin
                    if (SIGNED_MATH) begin
                        product = $signed(matrix_a[r][k]) * $signed(matrix_b[k][c]);
                        total = total + {{(ACC_WIDTH-DATA_WIDTH-WEIGHT_WIDTH){product[DATA_WIDTH+WEIGHT_WIDTH-1]}}, product};
                    end else
                        total = total + $unsigned(matrix_a[r][k]) * $unsigned(matrix_b[k][c]);
                end
                expected_c[r][c] = total;
            end
        end
    endtask

    task automatic send_weight(input integer k, input bit gaps);
        integer cycles, c, gap_count;
        bit accepted;
        if (gaps) begin
            gap_count = $urandom_range(1, 3);
            repeat (gap_count) begin
                @(negedge clk);
                weight_valid = 0;
                weight_data = '1; // Invalid data must be ignored.
                @(posedge clk);
            end
        end
        @(negedge clk);
        for (c = 0; c < ARRAY_COLS; c = c + 1)
            weight_data[c*WEIGHT_WIDTH +: WEIGHT_WIDTH] = matrix_b[k][c];
        weight_valid = 1;
        accepted = 0;
        for (cycles = 0; cycles < TB_TIMEOUT_CYCLES && !accepted; cycles = cycles + 1) begin
            @(posedge clk);
            accepted = (weight_ready === 1'b1);
        end
        if (!accepted) $fatal(1, "Timed out waiting for weight_ready");
    endtask

    task automatic load_weights(input bit gaps);
        integer k, r;
        // Existing top-level loading contract: repeat each B row ARRAY_ROWS times.
        for (k = 0; k < K_DIM; k = k + 1)
            for (r = 0; r < ARRAY_ROWS; r = r + 1)
                send_weight(k, gaps);
        @(negedge clk);
        weight_valid = 0;
        weight_data = 0;
    endtask

    task automatic send_activation(input integer k, input bit gaps);
        integer cycles, r, gap_count;
        bit accepted;
        if (gaps) begin
            gap_count = $urandom_range(1, 3);
            repeat (gap_count) begin
                @(negedge clk);
                act_valid = 0;
                act_data = '1;
                @(posedge clk);
            end
        end
        @(negedge clk);
        for (r = 0; r < ARRAY_ROWS; r = r + 1)
            act_data[r*DATA_WIDTH +: DATA_WIDTH] = matrix_a[r][k];
        act_valid = 1;
        accepted = 0;
        for (cycles = 0; cycles < TB_TIMEOUT_CYCLES && !accepted; cycles = cycles + 1) begin
            @(posedge clk);
            accepted = (act_ready === 1'b1);
        end
        if (!accepted) $fatal(1, "Timed out waiting for act_ready");
    endtask

    task automatic stream_activations(input bit gaps);
        integer k;
        for (k = 0; k < K_DIM; k = k + 1) send_activation(k, gaps);
        @(negedge clk);
        act_valid = 0;
        act_data = 0;
    endtask

    task automatic collect_results(input bit backpressure);
        integer cycle, count, c, initial_stall;
        bit held_valid, first_seen, completed;
        reg [ARRAY_COLS*ACC_WIDTH-1:0] held_data;
        count = 0;
        initial_stall = 0;
        held_valid = 0;
        first_seen = 0;
        completed = 0;
        for (cycle = 0; cycle < TB_TIMEOUT_CYCLES && !completed; cycle = cycle + 1) begin
            @(negedge clk);
            if (backpressure && (!first_seen || initial_stall < 3)) begin
                result_ready = 0;
                if (first_seen) initial_stall = initial_stall + 1;
            end else begin
                result_ready = !backpressure || ((cycle % 5) > 1);
            end
            @(posedge clk);
            if (result_valid !== 1'b0 && result_valid !== 1'b1)
                $fatal(1, "Unknown result_valid");
            if (held_valid && (result_valid !== 1'b1 || result_data !== held_data))
                $fatal(1, "Stalled result changed or valid dropped");
            held_valid = result_valid && !result_ready;
            held_data = result_data;
            first_seen = first_seen || result_valid;
            if (result_valid && result_ready) begin
                if (count >= ARRAY_ROWS) $fatal(1, "Extra result row");
                for (c = 0; c < ARRAY_COLS; c = c + 1) begin
                    if (result_data[c*ACC_WIDTH +: ACC_WIDTH] !== expected_c[count][c])
                        $fatal(1, "C[%0d][%0d] mismatch: expected 0x%0h, got 0x%0h",
                               count, c, expected_c[count][c], result_data[c*ACC_WIDTH +: ACC_WIDTH]);
                end
                count = count + 1;
            end
            if (done === 1'b1) begin
                if (count != ARRAY_ROWS)
                    $fatal(1, "Expected %0d result rows, received %0d", ARRAY_ROWS, count);
                if (held_valid) $fatal(1, "done asserted with an unaccepted result");
                if (busy !== 1'b0) $fatal(1, "busy active at done");
                completed = 1;
            end
        end
        if (!completed) $fatal(1, "Timed out waiting for done");
        repeat (2) begin
            @(posedge clk);
            if (done !== 1'b0) $fatal(1, "done is not a one-cycle pulse");
            if (result_valid !== 1'b0) $fatal(1, "Extra result after done");
        end
        @(negedge clk);
        result_ready = 0;
    endtask

    task automatic run_case(input [255:0] kind, input bit gaps, input bit backpressure);
        fill_matrices(kind);
        compute_expected();
        test_num = test_num + 1;
        $display("Test %0d: %s, gaps=%0d, backpressure=%0d", test_num, kind, gaps, backpressure);
        fork
            begin
                begin_job();
                load_weights(gaps);
                stream_activations(gaps);
            end
            collect_results(backpressure);
        join
        $display("Test %0d: PASSED", test_num);
    endtask

    task automatic reset_recovery(input bit during_compute);
        fill_matrices("random");
        begin_job();
        if (during_compute) begin
            load_weights(0);
            send_activation(0, 0);
        end else begin
            send_weight(0, 0);
        end
        reset_dut();
        run_case("simple", 0, 0);
    endtask

    initial begin
        integer seed, seed_dummy;
        reg [1023:0] vcdfile;
        if (ARRAY_ROWS < 1 || ARRAY_COLS < 1 || K_DIM < 1 ||
            DATA_WIDTH < 1 || WEIGHT_WIDTH < 1 || ACC_WIDTH < DATA_WIDTH + WEIGHT_WIDTH ||
            TB_TIMEOUT_CYCLES < 1 || INPUT_SKEW != 1)
            $fatal(1, "Invalid bench parameters; automatic input skewing is required");
        seed = 1;
        seed_dummy = $value$plusargs("SEED=%d", seed);
        $display("TB seed=%0d", seed);
        seed_dummy = $urandom(seed);
        seed_dummy = $value$plusargs("TEST=%s", selected_test);
        if ($value$plusargs("VCDFILE=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb);
        end
        $display("M=%0d N=%0d K=%0d signed=%0d; TEST=%s", ARRAY_ROWS, ARRAY_COLS, K_DIM, SIGNED_MATH, selected_test);
        reset_dut();
        if (selected_test == "all" || selected_test == "simple") run_case("simple", 0, 0);
        if (selected_test == "all" || selected_test == "identity") run_case("identity", 0, 0);
        if (selected_test == "all" || selected_test == "random") repeat (5) run_case("random", 0, 0);
        if (selected_test == "all" || selected_test == "zero") run_case("zero", 0, 0);
        if (selected_test == "all" || selected_test == "signed") begin
            if (SIGNED_MATH) run_case("signed", 0, 0);
            else if (selected_test == "signed") $fatal(1, "signed test requires SIGNED_MATH=1");
        end
        if (selected_test == "all" || selected_test == "limits") run_case("limits", 0, 0);
        if (selected_test == "all" || selected_test == "input_gaps") run_case("random", 1, 0);
        if (selected_test == "all" || selected_test == "output_backpressure") run_case("random", 0, 1);
        if (selected_test == "all" || selected_test == "stalls") run_case("random", 1, 1);
        if (selected_test == "all" || selected_test == "back_to_back") begin
            run_case("simple", 0, 0);
            run_case("zero", 0, 0);
            run_case("random", 0, 0);
        end
        if (selected_test == "all" || selected_test == "reset_weights") reset_recovery(0);
        if (selected_test == "all" || selected_test == "reset_compute") reset_recovery(1);
        if (test_num == 0) $fatal(1, "Unknown or empty TEST=%s", selected_test);
        $display("ALL TESTS PASSED (%0d transactions)", test_num);
        $finish;
    end

    initial begin
        #(SIM_TIMEOUT);
        $fatal(1, "Global simulation timeout");
    end
endmodule
