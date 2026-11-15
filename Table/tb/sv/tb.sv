`timescale 1ns/1ps
module tb;
    parameter TABLE_SIZE = 32, DATA_WIDTH = 8, INPUT_RATE = 2, OUTPUT_RATE = 2;
    parameter TB_TIMEOUT_CYCLES = 10000;
    localparam INDEX_WIDTH = (TABLE_SIZE < 2) ? 1 : $clog2(TABLE_SIZE);
    reg clk = 0, rst = 0, rd_en = 0;
    reg [INPUT_RATE-1:0] wr_en = 0;
    reg [INPUT_RATE*INDEX_WIDTH-1:0] index_wr = 0;
    reg [OUTPUT_RATE*INDEX_WIDTH-1:0] index_rd = 0;
    reg [INPUT_RATE*DATA_WIDTH-1:0] data_wr = 0;
    wire [OUTPUT_RATE*DATA_WIDTH-1:0] data_rd;
`ifdef TABLE_NETLIST
    table_top dut (.*);
`else
    table_top #(.TABLE_SIZE(TABLE_SIZE), .DATA_WIDTH(DATA_WIDTH),
                .INPUT_RATE(INPUT_RATE), .OUTPUT_RATE(OUTPUT_RATE)) dut (.*);
`endif
    reg [DATA_WIDTH-1:0] expected [0:TABLE_SIZE-1];
    reg [OUTPUT_RATE*DATA_WIDTH-1:0] expected_output = 0;
    reg [31:0] random_state;
    integer cycles = 0, transactions = 0;
    integer i, port_number, bit_number, address;
    string wave_file;

    task next_random;
        begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
        end
    endtask

    task step;
        integer p, a;
        begin
            cycles = cycles + 1;
            if (cycles > TB_TIMEOUT_CYCLES) $fatal(1, "Table timed out");
            #4;
            if (data_rd !== expected_output) $fatal(1, "output changed before clock");
            for (p = 0; p < INPUT_RATE; p = p + 1) begin
                a = index_wr[p*INDEX_WIDTH +: INDEX_WIDTH];
                if (wr_en[p] && a < TABLE_SIZE)
                    expected[a] = data_wr[p*DATA_WIDTH +: DATA_WIDTH];
            end
            if (rd_en) begin
                for (p = 0; p < OUTPUT_RATE; p = p + 1) begin
                    a = index_rd[p*INDEX_WIDTH +: INDEX_WIDTH];
                    expected_output[p*DATA_WIDTH +: DATA_WIDTH] = (a < TABLE_SIZE) ? expected[a] : 0;
                end
            end
            clk = 1;
            #2;
            if (data_rd !== expected_output)
                $fatal(1, "Table mismatch transaction=%0d expected=%h actual=%h", transactions, expected_output, data_rd);
            clk = 0;
            #2;
            transactions = transactions + 1;
        end
    endtask

    task reset_table;
        integer a;
        begin
            clk = 0;
            #1 rst = 1;
            for (a = 0; a < TABLE_SIZE; a = a + 1) expected[a] = 0;
            expected_output = 0;
            #1;
            if (data_rd !== 0) $fatal(1, "Table asynchronous reset failed");
            #1 rst = 0;
            wr_en = 0;
            rd_en = 0;
            step();
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
        // Invalid addresses have deterministic zero reads and ignored writes.
        if (TABLE_SIZE < 2**INDEX_WIDTH) begin
            index_wr = {INPUT_RATE{ {INDEX_WIDTH{1'b1}} }};
            index_rd = {OUTPUT_RATE{ {INDEX_WIDTH{1'b1}} }};
            wr_en = {INPUT_RATE{1'b1}};
            data_wr = {INPUT_RATE*DATA_WIDTH{1'b1}};
            rd_en = 1;
            step();
        end
        for (i = 0; i < TABLE_SIZE; i = i + 1) begin
            for (port_number = 0; port_number < INPUT_RATE; port_number = port_number + 1) begin
                index_wr[port_number*INDEX_WIDTH +: INDEX_WIDTH] = i;
                data_wr[port_number*DATA_WIDTH +: DATA_WIDTH] = i + port_number + 1;
            end
            for (port_number = 0; port_number < OUTPUT_RATE; port_number = port_number + 1)
                index_rd[port_number*INDEX_WIDTH +: INDEX_WIDTH] = i;
            wr_en = {INPUT_RATE{1'b1}};
            rd_en = 1;
            step(); // all writers and readers collide; highest writer wins
            wr_en = 0;
            step();
        end
        for (i = 0; i < 1500; i = i + 1) begin
            for (bit_number = 0; bit_number < INPUT_RATE*DATA_WIDTH; bit_number = bit_number + 1) begin
                next_random();
                data_wr[bit_number] = random_state[0];
            end
            for (port_number = 0; port_number < INPUT_RATE; port_number = port_number + 1) begin
                next_random();
                wr_en[port_number] = random_state[0];
                index_wr[port_number*INDEX_WIDTH +: INDEX_WIDTH] = random_state >> 1;
            end
            for (port_number = 0; port_number < OUTPUT_RATE; port_number = port_number + 1) begin
                next_random();
                index_rd[port_number*INDEX_WIDTH +: INDEX_WIDTH] = random_state;
            end
            next_random();
            rd_en = random_state[0];
            step();
            if (i % 251 == 0) reset_table();
        end
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end
endmodule