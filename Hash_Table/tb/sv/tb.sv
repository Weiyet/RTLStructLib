`timescale 1ns/1ps
module tb;
    parameter KEY_WIDTH = 32, VALUE_WIDTH = 32, TOTAL_INDEX = 8, CHAINING_SIZE = 4;
    parameter TB_TIMEOUT_CYCLES = 100;
    localparam COUNT_WIDTH = (CHAINING_SIZE < 2) ? 1 : $clog2(CHAINING_SIZE+1);
    localparam CAPACITY = TOTAL_INDEX * CHAINING_SIZE;
    reg clk = 0, rst = 0, op_en = 0;
    reg [KEY_WIDTH-1:0] key_in = 0;
    reg [VALUE_WIDTH-1:0] value_in = 0;
    reg [1:0] op_sel = 0;
    wire [VALUE_WIDTH-1:0] value_out;
    wire op_done, op_error;
    wire [COUNT_WIDTH-1:0] collision_count;
`ifdef HASH_NETLIST
    hash_table dut (.*);
`else
    hash_table #(.KEY_WIDTH(KEY_WIDTH), .VALUE_WIDTH(VALUE_WIDTH),
                 .TOTAL_INDEX(TOTAL_INDEX), .CHAINING_SIZE(CHAINING_SIZE)) dut (.*);
`endif
    always #5 clk = ~clk;
    reg valid [0:CAPACITY-1];
    reg [KEY_WIDTH-1:0] model_key [0:CAPACITY-1];
    reg [VALUE_WIDTH-1:0] model_value [0:CAPACITY-1];
    integer transactions = 0;
    integer i, bit_number;
    reg [31:0] random_state;
    reg [KEY_WIDTH-1:0] random_key;
    reg [VALUE_WIDTH-1:0] random_value;
    string wave_file;

    task next_random;
        begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
        end
    endtask

    task reset_table;
        integer entry;
        begin
            @(negedge clk);
            op_en = 0;
            #1 rst = 1;
            for (entry = 0; entry < CAPACITY; entry = entry + 1) valid[entry] = 0;
            #1;
            if (op_done !== 0 || op_error !== 0 || value_out !== 0 || collision_count !== 0)
                $fatal(1, "Hash Table asynchronous reset failed");
            @(negedge clk);
            rst = 0;
        end
    endtask

    task operation(input reg [1:0] action, input reg [KEY_WIDTH-1:0] key,
                   input reg [VALUE_WIDTH-1:0] value);
        integer entry, found, unused, occupancy, bucket_number, waited;
        reg expected_error;
        reg [VALUE_WIDTH-1:0] expected_value;
        begin
            found = -1;
            unused = -1;
            occupancy = 0;
            bucket_number = $unsigned(key) % TOTAL_INDEX;
            for (entry = 0; entry < CAPACITY; entry = entry + 1) begin
                if (valid[entry]) begin
                    if (model_key[entry] == key) found = entry;
                    if ($unsigned(model_key[entry]) % TOTAL_INDEX == bucket_number)
                        occupancy = occupancy + 1;
                end else if (unused < 0) unused = entry;
            end
            expected_error = 0;
            expected_value = 0;
            case (action)
                0: begin
                    if (found >= 0) model_value[found] = value;
                    else if (occupancy == CHAINING_SIZE) expected_error = 1;
                    else begin
                        valid[unused] = 1;
                        model_key[unused] = key;
                        model_value[unused] = value;
                        occupancy = occupancy + 1;
                    end
                end
                1: begin
                    if (found < 0) expected_error = 1;
                    else begin valid[found] = 0; occupancy = occupancy - 1; end
                end
                2: begin
                    if (found < 0) expected_error = 1;
                    else expected_value = model_value[found];
                end
                3: begin expected_error = 1; occupancy = 0; end
            endcase
            @(negedge clk);
            key_in = key;
            value_in = value;
            op_sel = action;
            op_en = 1;
            @(posedge clk);
            #1;
            waited = 1;
            if (op_done !== 0) $fatal(1, "completion before search");
            @(negedge clk);
            op_en = 0;
            key_in = ~key;
            value_in = ~value;
            op_sel = ~action;
            while (!op_done) begin
                if (waited >= TB_TIMEOUT_CYCLES || waited > CHAINING_SIZE + 2)
                    $fatal(1, "Hash Table timed out");
                @(posedge clk);
                #1;
                waited = waited + 1;
            end
            if (op_error !== expected_error || value_out !== expected_value ||
                collision_count !== occupancy)
                $fatal(1, "Hash mismatch op=%d key=%h error=%b/%b value=%h/%h count=%d/%d",
                       action, key, op_error, expected_error, value_out, expected_value,
                       collision_count, occupancy);
            @(posedge clk);
            #1;
            if (op_done !== 0 || op_error !== 0) $fatal(1, "completion must pulse for one cycle");
            transactions = transactions + 1;
        end
    endtask

    initial begin
        if (!$value$plusargs("SEED=%d", random_state)) random_state = 123;
        if (random_state == 0) random_state = 32'h9e3779b9;
        if ($value$plusargs("VCDFILE=%s", wave_file)) begin
            $dumpfile(wave_file);
            $dumpvars(0, tb);
        end
        #120;
        reset_table();
        operation(2, 0, 0);
        operation(1, 0, 0);
        for (i = 0; i < CHAINING_SIZE + 2; i = i + 1) operation(0, i*TOTAL_INDEX, i+1);
        operation(0, 0, {VALUE_WIDTH{1'b1}}); // update even when full
        for (i = 0; i < CHAINING_SIZE; i = i + 1) operation(2, i*TOTAL_INDEX, 0);
        operation(1, (CHAINING_SIZE/2)*TOTAL_INDEX, 0);
        for (i = 0; i < CHAINING_SIZE; i = i + 1) operation(2, i*TOTAL_INDEX, 0);
        operation(0, (CHAINING_SIZE+1)*TOTAL_INDEX, 123);
        operation(3, 0, 0);
        reset_table();
        for (i = 0; i < KEY_WIDTH; i = i + 1) begin
            random_key = 0;
            random_key[i] = 1;
            operation(0, random_key, {VALUE_WIDTH{1'b1}});
            operation(2, random_key, 0);
            operation(1, random_key, 0);
        end
        for (i = 0; i < 800; i = i + 1) begin
            for (bit_number = 0; bit_number < KEY_WIDTH; bit_number = bit_number + 1) begin
                next_random();
                random_key[bit_number] = random_state[0];
            end
            for (bit_number = 0; bit_number < VALUE_WIDTH; bit_number = bit_number + 1) begin
                next_random();
                random_value[bit_number] = random_state[0];
            end
            // A small key range forces duplicates, hits and collisions.
            if (i % 2 == 0) random_key = random_key % (2*CAPACITY);
            next_random();
            operation(random_state % 4, random_key, random_value);
            if (i % 199 == 0) reset_table();
        end
        @(negedge clk);
        op_en = 1;
        op_sel = 0;
        key_in = 0;
        @(posedge clk);
        reset_table(); // abort a captured request before its first search edge
        operation(2, 0, 0);
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end
endmodule