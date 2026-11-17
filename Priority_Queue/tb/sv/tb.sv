`timescale 1ns/1ps
module tb;
    parameter DEPTH = 16, PRIORITY_WIDTH = 8, DATA_WIDTH = 8, MIN_FIRST = 1;
    parameter TB_TIMEOUT_CYCLES = 100000;
    localparam COUNT_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH+1);
    reg clk = 0, rst = 0, req_valid = 0, rsp_ready = 0;
    reg [1:0] req_op = 0;
    reg [PRIORITY_WIDTH-1:0] req_priority = 0;
    reg [DATA_WIDTH-1:0] req_data = 0;
    wire req_ready, rsp_valid, rsp_error, full, empty;
    wire [PRIORITY_WIDTH-1:0] rsp_priority;
    wire [DATA_WIDTH-1:0] rsp_data;
    wire [COUNT_WIDTH-1:0] count;
`ifdef PRIORITY_QUEUE_NETLIST
    priority_queue dut (.*);
`else
    priority_queue #(.DEPTH(DEPTH), .PRIORITY_WIDTH(PRIORITY_WIDTH),
                     .DATA_WIDTH(DATA_WIDTH), .MIN_FIRST(MIN_FIRST)) dut (.*);
`endif
    reg [PRIORITY_WIDTH-1:0] model_priority [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] model_data [0:DEPTH-1];
    integer used = 0, cycles = 0, transactions = 0;
    integer seed = 123, ignored, i, j, op;
    reg [63:0] random_bits;
    reg [1023:0] wavefile;

    task tick;
        begin
            cycles = cycles + 1;
            if (cycles > TB_TIMEOUT_CYCLES) $fatal(1, "Priority Queue timed out");
            clk = 0; #5; clk = 1; #5;
        end
    endtask

    task flags;
        begin
            if (count !== used || full !== (used == DEPTH) || empty !== (used == 0))
                $fatal(1, "Occupancy mismatch at transaction %0d: count=%0d expected=%0d", transactions, count, used);
        end
    endtask

    task reset_queue;
        begin
            clk = 0; req_valid = 0; rsp_ready = 0; rst = 0; #2;
            rst = 1; used = 0; #2;
            flags();
            if (req_ready !== 0 || rsp_valid !== 0 || rsp_error !== 0 || rsp_data !== 0 || rsp_priority !== 0)
                $fatal(1, "Reset outputs invalid");
            tick(); rst = 0; tick();
            if (req_ready !== 1) $fatal(1, "Not ready after reset");
        end
    endtask

    task command;
        input [1:0] operation;
        input [PRIORITY_WIDTH-1:0] priority_value;
        input [DATA_WIDTH-1:0] data_value;
        input integer stalls;
        integer k, latency, match_index;
        reg error_expected;
        reg [PRIORITY_WIDTH-1:0] best, saved_priority;
        reg [DATA_WIDTH-1:0] saved_data;
        begin
            if (req_ready !== 1) $fatal(1, "Not ready for request");
            error_expected = operation == 3 || (operation == 0 && used == DEPTH) ||
                             ((operation == 1 || operation == 2) && used == 0);
            best = 0;
            if (used > 0) best = model_priority[0];
            for (k = 1; k < used; k = k + 1)
                if (MIN_FIRST ? model_priority[k] < best : model_priority[k] > best)
                    best = model_priority[k];
            req_valid = 1; req_op = operation; req_priority = priority_value;
            req_data = data_value; rsp_ready = 0;
            tick();
            req_op = 3; req_priority = ~priority_value; req_data = ~data_value;
            latency = 0;
            while (rsp_valid !== 1) begin
                if (req_ready !== 0) $fatal(1, "Ready while busy");
                tick(); latency = latency + 1;
                if (latency > $clog2(DEPTH+1)+2) $fatal(1, "Operation timed out");
            end
            if (rsp_error !== error_expected) $fatal(1, "Error mismatch");
            if (error_expected || operation == 0) begin
                if (rsp_data !== 0 || rsp_priority !== 0) $fatal(1, "Nonzero acknowledgement");
            end else begin
                if (rsp_priority !== best) $fatal(1, "Priority mismatch");
                match_index = -1;
                for (k = 0; k < used; k = k + 1)
                    if (model_priority[k] === rsp_priority && model_data[k] === rsp_data) match_index = k;
                if (match_index < 0) $fatal(1, "Unexpected payload");
                if (operation == 1) begin
                    used = used - 1;
                    model_priority[match_index] = model_priority[used];
                    model_data[match_index] = model_data[used];
                end
            end
            if (!error_expected && operation == 0) begin
                model_priority[used] = priority_value; model_data[used] = data_value;
                used = used + 1;
            end
            flags(); saved_priority = rsp_priority; saved_data = rsp_data;
            for (k = 0; k < stalls; k = k + 1) begin
                tick(); flags();
                if (rsp_valid !== 1 || req_ready !== 0 || rsp_error !== error_expected ||
                    rsp_priority !== saved_priority || rsp_data !== saved_data)
                    $fatal(1, "Response changed under backpressure");
            end
            rsp_ready = 1; tick(); req_valid = 0;
            if (req_ready !== 1 || rsp_valid !== 0) $fatal(1, "Response not consumed");
            tick(); flags();
            if (req_ready !== 1 || rsp_valid !== 0) $fatal(1, "Accepted busy request");
            transactions = transactions + 1;
        end
    endtask

    initial begin
        ignored = $value$plusargs("SEED=%d", seed);
        ignored = $urandom(seed);
        if ($value$plusargs("VCDFILE=%s", wavefile)) begin
            $dumpfile(wavefile); $dumpvars(0, tb);
        end
        reset_queue();
        command(1, 0, 0, 2); command(2, 0, 0, 2); command(3, 0, 0, 2);
        for (j = 0; j < 3; j = j + 1) begin
            for (i = 0; i < DEPTH; i = i + 1)
                command(0, j == 0 ? i : j == 1 ? DEPTH-i : 0, i, 1);
            command(0, 0, 0, 1); command(3, 0, 0, 0);
            for (i = 0; i < DEPTH; i = i + 1) begin
                command(2, 0, 0, 1); command(1, 0, 0, 1);
            end
        end
        for (i = 0; i < 700; i = i + 1) begin
            random_bits = {$urandom, $urandom};
            op = $urandom_range(0, 99);
            command(op < 45 ? 0 : op < 80 ? 1 : op < 95 ? 2 : 3,
                    random_bits, random_bits ^ (random_bits >> 13), $urandom_range(0, 3));
        end
        while (used > 0) command(1, 0, 0, 0);
        // Reset during each operation, including pending response states.
        for (op = 0; op < 3; op = op + 1) begin
            for (j = 0; j < $clog2(DEPTH+1)+2; j = j + 1) begin
                reset_queue();
                for (i = 0; i < (DEPTH > 1 ? DEPTH-1 : 1); i = i + 1) command(0, i, i, 0);
                req_valid = 1; req_op = op; req_priority = MIN_FIRST ? 0 : '1;
                req_data = '1; rsp_ready = 0; tick(); req_valid = 0;
                for (i = 0; i < j; i = i + 1) tick();
                reset_queue();
                for (i = 0; i < $clog2(DEPTH+1)+3; i = i + 1) begin
                    tick(); flags();
                    if (rsp_valid !== 0) $fatal(1, "Stale completion after reset");
                end
                command(0, '1, '1, 0); command(1, 0, 0, 0);
            end
        end
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end
endmodule
