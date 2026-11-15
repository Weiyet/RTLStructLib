`timescale 1ns/1ps
module tb;
    parameter DEPTH = 16, DATA_WIDTH = 8, ASYNC = 1, RD_BUFFER = 1;
    parameter WR_HALF = 3, RD_HALF = 5, TB_TIMEOUT_CYCLES = 100000;
    reg wr_clk = 0, rd_clk = 0, rst = 0, wr_en = 0, rd_en = 0;
    reg [DATA_WIDTH-1:0] data_wr = 0;
    wire [DATA_WIDTH-1:0] data_rd;
    wire fifo_full, fifo_empty;
`ifdef FIFO_NETLIST
    fifo dut (.*);
`else
    fifo #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH), .ASYNC(ASYNC),
           .RD_BUFFER(RD_BUFFER)) dut (.*);
`endif
    reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] expected_output = 0;
    integer count = 0, ticks = 0, transactions = 0, phase = 0;
    integer i, j, round_number;
    reg next_wr, next_rd, push, pop;
    reg [31:0] random_state;
    reg [DATA_WIDTH-1:0] word_value;
    string wave_file;

    task next_random;
        begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
        end
    endtask

    task tick(input bit write_enable, input bit read_enable);
        begin
            ticks = ticks + 1;
            if (ticks > TB_TIMEOUT_CYCLES) $fatal(1, "FIFO timed out");
            wr_en = write_enable;
            rd_en = read_enable;
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                next_random();
                data_wr[j] = random_state[0];
            end
            #2; // setup before the scheduled active edges
            next_wr = ((phase / WR_HALF) % 2) != 0;
            next_rd = ASYNC ? (((phase / RD_HALF) % 2) != 0) : next_wr;
            push = next_wr && !wr_clk && wr_en && !fifo_full;
            pop = next_rd && !rd_clk && rd_en && !fifo_empty;
            if (RD_BUFFER == 0) begin
                if (rd_en && !fifo_empty) begin
                    if (count == 0 || data_rd !== expected[0])
                        $fatal(1, "combinational read mismatch count=%0d", count);
                end else if (data_rd !== 0) $fatal(1, "disabled read must be zero");
            end
            if (pop) begin
                if (count == 0) $fatal(1, "read accepted while empty");
                expected_output = expected[0];
                for (j = 0; j < count - 1; j = j + 1) expected[j] = expected[j+1];
                count = count - 1;
                transactions = transactions + 1;
            end
            if (push) begin
                if (count == DEPTH) $fatal(1, "write accepted while full");
                expected[count] = data_wr;
                count = count + 1;
                transactions = transactions + 1;
            end
            wr_clk = next_wr;
            rd_clk = next_rd;
            phase = phase + 1;
            #2;
            if (RD_BUFFER && data_rd !== expected_output)
                $fatal(1, "registered read mismatch expected=%h actual=%h", expected_output, data_rd);
            if (!ASYNC && (fifo_full !== (count == DEPTH) || fifo_empty !== (count == 0)))
                $fatal(1, "synchronous flags mismatch count=%0d full=%b empty=%b", count, fifo_full, fifo_empty);
        end
    endtask

    task reset_fifo;
        begin
            wr_clk = 0;
            rd_clk = 0;
            wr_en = 0;
            rd_en = 0;
            #1 rst = 1;
            count = 0;
            expected_output = 0;
            #1;
            if (fifo_empty !== 1 || data_rd !== 0) $fatal(1, "asynchronous reset failed");
            #5 rst = 0;
            phase = 0;
            // Warm up reset-release synchronizers without accepting traffic.
            repeat (8 * (WR_HALF + RD_HALF)) begin
                wr_clk = ((phase / WR_HALF) % 2) != 0;
                rd_clk = ASYNC ? (((phase / RD_HALF) % 2) != 0) : wr_clk;
                phase = phase + 1;
                #4;
            end
            if (fifo_full !== 0 || fifo_empty !== 1) $fatal(1, "reset release failed");
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
        reset_fifo();
        for (round_number = 0; round_number < 4; round_number = round_number + 1) begin
            repeat ((DEPTH + 8) * 2 * WR_HALF) tick(1, 0);
            if (count != DEPTH || fifo_full !== 1) $fatal(1, "capacity mismatch count=%0d", count);
            repeat ((DEPTH + 8) * 2 * RD_HALF) tick(0, 1);
            if (count != 0 || fifo_empty !== 1) $fatal(1, "drain lost entries count=%0d", count);
        end
        repeat (2000) tick(1, 1);
        reset_fifo();
        for (i = 0; i < 6000; i = i + 1) begin
            next_random();
            tick(random_state[0], random_state[1]);
        end
        repeat ((DEPTH + 8) * 2 * RD_HALF) tick(0, 1);
        if (count != 0) $fatal(1, "random drain incomplete");
        repeat ((DEPTH + 8) * 2 * WR_HALF) tick(1, 0);
        reset_fifo();
        repeat (100) tick(0, 1);
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end
endmodule