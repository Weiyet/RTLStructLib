`timescale 1ns / 1ps
// Independent fixed-array reference model; failures always stop the simulator.
module tb #(
    parameter DATA_WIDTH = 8,
    parameter LENGTH = 8,
    parameter SUM_METHOD = 0,
    parameter TB_TIMEOUT_CYCLES = 1000,
    localparam INDEX_WIDTH = (LENGTH > 1) ? $clog2(LENGTH) : 1,
    localparam OUT_WIDTH = DATA_WIDTH + INDEX_WIDTH
);
    localparam READ = 0, INSERT = 1, FIND_ALL = 2, FIND_FIRST = 3,
               SUM = 4, ASCENDING = 5, DESCENDING = 6, DELETE = 7;
    reg clk = 0, rst = 1, op_en = 0;
    reg [2:0] op_sel = 0;
    reg [DATA_WIDTH-1:0] data_in = 0;
    reg [INDEX_WIDTH-1:0] index_in = 0;
    wire [OUT_WIDTH-1:0] data_out;
    wire op_done, op_in_progress, op_error;
    wire [$clog2(LENGTH+1)-1:0] len;
    reg [DATA_WIDTH-1:0] model [0:LENGTH-1];
    integer count = 0, transactions = 0;
    string test_name;
    localparam [DATA_WIDTH-1:0] MAX_VALUE = {DATA_WIDTH{1'b1}};
    localparam [INDEX_WIDTH-1:0] MAX_INDEX = {INDEX_WIDTH{1'b1}};

    list #(.DATA_WIDTH(DATA_WIDTH), .LENGTH(LENGTH), .SUM_METHOD(SUM_METHOD)) DUT (
        .clk(clk), .rst(rst), .op_sel(op_sel), .op_en(op_en),
        .data_in(data_in), .index_in(index_in), .data_out(data_out),
        .op_done(op_done), .op_in_progress(op_in_progress), .op_error(op_error), .len(len)
    );
    always #5 clk = ~clk;

    task automatic reset_dut;
        integer item;
        begin
            @(negedge clk);
            rst = 1;
            op_en = 0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rst = 0;
            @(posedge clk);
            #1;
            if (len !== 0 || op_done !== 0 || op_in_progress !== 0 || op_error !== 0)
                $fatal(1, "Reset did not clear the List interface");
            count = 0;
            for (item = 0; item < LENGTH; item = item + 1)
                model[item] = 0;
            @(negedge clk);
        end
    endtask

    task automatic command(
        input integer operation,
        input [INDEX_WIDTH-1:0] index,
        input [DATA_WIDTH-1:0] value
    );
        integer cycle, item, other, target, match_count, match_seen;
        integer match_indices [0:LENGTH-1];
        reg expected_error, completed;
        reg [OUT_WIDTH-1:0] expected_data;
        reg [DATA_WIDTH-1:0] temporary;
        begin
            expected_error = 0;
            expected_data = 0;
            match_count = 0;
            match_seen = 0;
            completed = 0;
            case (operation)
                READ: begin
                    expected_error = (index >= count);
                    if (!expected_error)
                        expected_data = model[index];
                end
                INSERT: expected_error = (count == LENGTH);
                DELETE: expected_error = (index >= count);
                SUM: for (item = 0; item < count; item = item + 1)
                    expected_data = expected_data + model[item];
                FIND_FIRST, FIND_ALL: begin
                    for (item = 0; item < count; item = item + 1)
                        if (model[item] == value) begin
                            match_indices[match_count] = item;
                            match_count = match_count + 1;
                        end
                    expected_error = (match_count == 0);
                    if (!expected_error)
                        expected_data = match_indices[0];
                end
            endcase
            if (op_done !== 0 || op_in_progress !== 0)
                $fatal(1, "Previous operation did not finish");
            @(negedge clk);
            op_sel = operation;
            index_in = index;
            data_in = value;
            op_en = 1;
            cycle = 0;
            while (cycle < TB_TIMEOUT_CYCLES && !completed) begin
                @(posedge clk);
                #1;
                if (op_done && op_in_progress) begin
                    if (operation != FIND_ALL || op_error || match_seen >= match_count)
                        $fatal(1, "Unexpected intermediate completion in operation %0d", operation);
                    if (data_out !== match_indices[match_seen])
                        $fatal(1, "Search match %0d: got %0d, expected %0d",
                               match_seen, data_out, match_indices[match_seen]);
                    match_seen = match_seen + 1;
                end
                if (op_done && !op_in_progress) begin
                    completed = 1;
                    if (op_error !== expected_error)
                        $fatal(1, "Operation %0d error: got %0d, expected %0d",
                               operation, op_error, expected_error);
                    if (!expected_error && (operation == READ || operation == SUM || operation == FIND_FIRST))
                        if (data_out !== expected_data)
                            $fatal(1, "Operation %0d data: got %0d, expected %0d",
                                   operation, data_out, expected_data);
                    if (operation == FIND_ALL && match_seen != match_count)
                        $fatal(1, "Search returned %0d of %0d matches", match_seen, match_count);
                end else begin
                    @(negedge clk);
                    // Perturb inputs and request another insert while the DUT is busy.
                    op_en = op_in_progress;
                    op_sel = INSERT;
                    index_in = MAX_INDEX;
                    data_in = ~value;
                end
                cycle = cycle + 1;
            end
            if (!completed)
                $fatal(1, "Operation %0d timed out", operation);
            if (!expected_error) begin
                case (operation)
                    INSERT: begin
                        target = (index >= count) ? count : index;
                        for (item = LENGTH-1; item > 0; item = item - 1)
                            if (item > target)
                                model[item] = model[item-1];
                        model[target] = value;
                        count = count + 1;
                    end
                    DELETE: begin
                        for (item = 0; item < LENGTH-1; item = item + 1)
                            if (item >= index)
                                model[item] = model[item+1];
                        count = count - 1;
                        model[count] = 0;
                    end
                    ASCENDING, DESCENDING: begin
                        for (item = 0; item < count; item = item + 1)
                            for (other = item+1; other < count; other = other + 1)
                                if ((operation == ASCENDING && model[item] > model[other]) ||
                                    (operation == DESCENDING && model[item] < model[other])) begin
                                    temporary = model[item];
                                    model[item] = model[other];
                                    model[other] = temporary;
                                end
                    end
                endcase
            end
            if (len !== count)
                $fatal(1, "Length: got %0d, expected %0d", len, count);
            transactions = transactions + 1;
            @(negedge clk);
            op_en = 0;
            @(posedge clk);
            #1;
            if (op_done !== 0 || op_in_progress !== 0)
                $fatal(1, "Completion did not clear on the next clock");
            @(negedge clk);
        end
    endtask

    task automatic check_contents;
        integer item;
        begin
            for (item = 0; item < count; item = item + 1)
                command(READ, item, 0);
        end
    endtask

    task automatic empty_tests;
        begin
            reset_dut();
            command(READ, 0, 0);
            command(DELETE, 0, 0);
            command(FIND_FIRST, 0, 0);
            command(FIND_ALL, 0, 0);
            command(FIND_FIRST, 0, MAX_VALUE);
            command(FIND_ALL, 0, MAX_VALUE);
            command(SUM, 0, 0);
            command(ASCENDING, 0, 0);
            command(DESCENDING, 0, 0);
            command(INSERT, 0, MAX_VALUE);
            command(SUM, 0, 0);
        end
    endtask

    task automatic boundary_tests;
        integer item;
        begin
            reset_dut();
            for (item = 0; item < LENGTH; item = item + 1) begin
                command(INSERT, (item % 2) ? 0 : MAX_INDEX, item + 1);
                check_contents();
            end
            command(INSERT, 0, MAX_VALUE);
            check_contents();
            for (item = 0; item < LENGTH; item = item + 1) begin
                command(DELETE, count/2, 0);
                check_contents();
                command(SUM, 0, 0);
            end
            command(DELETE, 0, 0);
            command(READ, 0, 0);
        end
    endtask

    task automatic search_tests;
        integer item;
        begin
            reset_dut();
            for (item = 0; item < LENGTH; item = item + 1)
                command(INSERT, item, (item % 2) ? 0 : MAX_VALUE);
            command(FIND_FIRST, 0, 0);
            command(FIND_ALL, 0, 0);
            command(FIND_FIRST, 0, MAX_VALUE);
            command(FIND_ALL, 0, MAX_VALUE);
            check_contents();
            reset_dut();
            for (item = 0; item < LENGTH; item = item + 1)
                command(INSERT, item, 0);
            command(FIND_FIRST, 0, MAX_VALUE);
            command(FIND_ALL, 0, MAX_VALUE);
            command(FIND_ALL, 0, 0);
        end
    endtask

    task automatic sum_tests;
        integer item;
        begin
            reset_dut();
            for (item = 0; item < LENGTH; item = item + 1)
                command(INSERT, item, MAX_VALUE);
            repeat (3) command(SUM, 0, 0);
            command(DELETE, 0, 0);
            command(SUM, 0, 0);
            command(INSERT, 0, 1);
            command(SUM, 0, 0);
            check_contents();
        end
    endtask

    task automatic sort_tests;
        integer pattern, item;
        reg [DATA_WIDTH-1:0] value;
        begin
            for (pattern = 0; pattern < 4; pattern = pattern + 1) begin
                reset_dut();
                for (item = 0; item < LENGTH; item = item + 1) begin
                    case (pattern)
                        0: value = item;
                        1: value = LENGTH-1-item;
                        2: value = (item % 2) ? MAX_VALUE : 0;
                        3: value = MAX_VALUE;
                    endcase
                    command(INSERT, item, value);
                end
                command(ASCENDING, 0, 0);
                check_contents();
                command(DESCENDING, 0, 0);
                check_contents();
                command(ASCENDING, 0, 0);
                check_contents();
                command(SUM, 0, 0);
            end
        end
    endtask

    task automatic random_tests;
        integer trial, operation;
        reg [DATA_WIDTH-1:0] value;
        begin
            reset_dut();
            for (trial = 0; trial < 120; trial = trial + 1) begin
                operation = $urandom_range(0, 7);
                value = {$urandom, $urandom}; // Exercise values wider than an integer.
                command(operation, $urandom_range(0, MAX_INDEX), value);
                if (operation == INSERT || operation == DELETE ||
                    operation == ASCENDING || operation == DESCENDING)
                    check_contents();
            end
            check_contents();
        end
    endtask

    task automatic reset_tests;
        integer operation, item;
        begin
            for (operation = 0; operation < 3; operation = operation + 1) begin
                reset_dut();
                for (item = 0; item < LENGTH; item = item + 1)
                    command(INSERT, item, MAX_VALUE - (item % 2));
                @(negedge clk);
                case (operation)
                    0: op_sel = SUM;
                    1: op_sel = ASCENDING;
                    2: op_sel = FIND_ALL;
                endcase
                data_in = MAX_VALUE;
                op_en = 1;
                @(posedge clk);
                @(negedge clk);
                op_en = 0;
                reset_dut();
                repeat (LENGTH + 3) begin
                    @(posedge clk);
                    #1;
                    if (op_done !== 0 || op_in_progress !== 0)
                        $fatal(1, "Aborted operation completed after reset");
                end
                command(INSERT, 0, 1);
                command(SUM, 0, 0);
                command(READ, 0, 0);
            end
        end
    endtask

    initial begin
        string waveform;
        integer seed, seed_result;
        seed = 1;
        if ($value$plusargs("SEED=%d", seed))
            seed_result = $urandom(seed);
        if ($value$plusargs("VCDFILE=%s", waveform)) begin
            $dumpfile(waveform);
            $dumpvars(0, tb);
        end
        if (!$value$plusargs("TEST=%s", test_name))
            test_name = "all";
        if (test_name == "all" || test_name == "empty") empty_tests();
        if (test_name == "all" || test_name == "boundaries") boundary_tests();
        if (test_name == "all" || test_name == "search") search_tests();
        if (test_name == "all" || test_name == "sum") sum_tests();
        if (test_name == "all" || test_name == "sort") sort_tests();
        if (test_name == "all" || test_name == "random") random_tests();
        if (test_name == "all" || test_name == "reset") reset_tests();
        if (transactions == 0)
            $fatal(1, "Unknown TEST selector: %s", test_name);
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Global simulation timeout");
    end
endmodule
