`timescale 1ns/1ps
module tb;
    parameter DEPTH = 12;
    parameter DATA_WIDTH = 8;
    parameter TB_TIMEOUT_CYCLES = 20000;
    reg clk = 0, rst = 0, wr_en = 0, rd_en = 0;
    reg [DATA_WIDTH-1:0] data_wr = 0;
    wire [DATA_WIDTH-1:0] data_rd;
    wire lifo_full, lifo_empty;
`ifdef LIFO_NETLIST
    lifo dut (.*);
`else
    lifo #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH)) dut (.*);
`endif
    always #5 clk = ~clk;
    reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] expected_output = 0;
    integer count = 0, transactions = 0, cycles = 0;
    integer i, round_number, bit_number;
    reg [31:0] random_state;
    reg [DATA_WIDTH-1:0] random_word;
    string wave_file;

    always @(posedge clk) begin
        cycles = cycles + 1;
        if (cycles > TB_TIMEOUT_CYCLES)
            $fatal(1, "LIFO timed out after %0d cycles", cycles);
    end

    task check_outputs;
        begin
            if (lifo_empty !== (count == 0) || lifo_full !== (count == DEPTH))
                $fatal(1, "flags: transaction=%0d count=%0d empty=%b full=%b",
                       transactions, count, lifo_empty, lifo_full);
            if (data_rd !== expected_output)
                $fatal(1, "data: transaction=%0d expected=%h actual=%h",
                       transactions, expected_output, data_rd);
        end
    endtask

    task step(input bit push, input bit pop, input reg [DATA_WIDTH-1:0] value);
        begin
            @(negedge clk);
            wr_en = push;
            rd_en = pop;
            data_wr = value;
            @(posedge clk);
            if (push && pop)
                expected_output = value;
            else if (push && count < DEPTH) begin
                expected[count] = value;
                count = count + 1;
            end else if (pop && count > 0) begin
                count = count - 1;
                expected_output = expected[count];
            end
            transactions = transactions + 1;
            #1;
            check_outputs();
        end
    endtask

    task reset_stack;
        begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 1;
            #1 rst = 1;
            count = 0;
            expected_output = 0;
            #1 check_outputs(); // asynchronous assertion before the next edge
            @(negedge clk);
            wr_en = 0;
            rd_en = 0;
            rst = 0;
            step(0, 0, 0);
        end
    endtask

    task next_random;
        begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
        end
    endtask

    initial begin
        if (!$value$plusargs("SEED=%d", random_state)) random_state = 123;
        if (random_state == 0) random_state = 32'h9e3779b9;
        if ($value$plusargs("VCDFILE=%s", wave_file)) begin
            $dumpfile(wave_file);
            $dumpvars(0, tb);
        end
        // Xilinx mapped cells have a 100ns global startup reset.
        repeat (12) @(negedge clk);
        reset_stack();
        step(0, 1, 0);
        step(1, 1, {DATA_WIDTH{1'b1}});
        for (round_number = 0; round_number < 3; round_number = round_number + 1) begin
            for (i = 0; i < DEPTH; i = i + 1) step(1, 0, i + round_number);
            step(1, 0, 0);
            step(1, 1, {DATA_WIDTH{1'b1}});
            step(0, 0, 0);
            for (i = 0; i < DEPTH; i = i + 1) step(0, 1, 0);
            step(0, 1, 0);
        end
        for (i = 0; i < 1200; i = i + 1) begin
            for (bit_number = 0; bit_number < DATA_WIDTH; bit_number = bit_number + 1) begin
                next_random();
                random_word[bit_number] = random_state[0];
            end
            next_random();
            step(random_state[0], random_state[1], random_word);
            if (i % 197 == 0) reset_stack();
        end
        reset_stack();
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            random_word = 0;
            random_word[i] = 1;
            step(1, 0, random_word);
            step(0, 1, 0);
        end
        for (i = 0; i < DEPTH; i = i + 1) step(1, 0, i);
        reset_stack();
        step(0, 1, 0);
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end
endmodule