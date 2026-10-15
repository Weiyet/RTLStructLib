`timescale 1ns / 1ps
// Shared ordered-address model for the NULL-terminated SLL and DLL hardware.
module tb #(
    parameter DATA_WIDTH = 8,
    parameter MAX_NODE = 8,
    parameter TB_TIMEOUT_CYCLES = 1000,
    localparam ADDR_WIDTH = $clog2(MAX_NODE+1)
);
    localparam READ_ADDR = 0, INSERT_ADDR = 1, DELETE_VALUE = 2, DELETE_ADDR = 3,
               INSERT_INDEX = 5, DELETE_INDEX = 7;
    localparam [DATA_WIDTH-1:0] MAX_DATA = {DATA_WIDTH{1'b1}};
    localparam [ADDR_WIDTH-1:0] MAX_ADDR = {ADDR_WIDTH{1'b1}};
    reg clk = 0, rst = 1, op_start = 0;
    reg [2:0] op = 0;
    reg [DATA_WIDTH-1:0] data_in = 0;
    reg [ADDR_WIDTH-1:0] addr_in = 0;
    wire op_done, fault, full, empty;
    wire [DATA_WIDTH-1:0] data_out;
    wire [ADDR_WIDTH-1:0] pre_node_addr, next_node_addr, length, head, tail;
    reg [DATA_WIDTH-1:0] model_data [0:MAX_NODE-1];
    integer model_addr [0:MAX_NODE-1];
    integer count = 0, transactions = 0;
    string test_name;
`ifdef LINKED_LIST_DOUBLY
    localparam BIDIRECTIONAL = 1;
`else
    localparam BIDIRECTIONAL = 0;
    assign pre_node_addr = MAX_NODE;
`endif

`ifdef LINKED_LIST_NETLIST
    `LINKED_LIST_DUT DUT (
`else
    `LINKED_LIST_DUT #(.DATA_WIDTH(DATA_WIDTH), .MAX_NODE(MAX_NODE)) DUT (
`endif
        .clk(clk), .rst(rst), .data_in(data_in), .addr_in(addr_in), .op(op),
        .op_start(op_start), .op_done(op_done), .data_out(data_out),
`ifdef LINKED_LIST_DOUBLY
        .pre_node_addr(pre_node_addr),
`endif
        .next_node_addr(next_node_addr),
        .length(length), .head(head), .tail(tail), .full(full), .empty(empty),
        .fault(fault)
    );
    always #5 clk = ~clk;

    task automatic check_status;
        begin
            if (length !== count || empty !== (count == 0) || full !== (count == MAX_NODE))
                $fatal(1, "Status mismatch: length %0d, expected %0d", length, count);
            if (head !== ((count == 0) ? MAX_NODE : model_addr[0]) ||
                tail !== ((count == 0) ? MAX_NODE : model_addr[count-1]))
                $fatal(1, "Head/tail mismatch: got %0d/%0d", head, tail);
        end
    endtask

    task automatic reset_dut;
        integer item;
        begin
            @(negedge clk);
            rst = 1;
            op_start = 0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rst = 0;
            @(posedge clk);
            #1;
            count = 0;
            for (item = 0; item < MAX_NODE; item = item + 1) begin
                model_addr[item] = MAX_NODE;
                model_data[item] = 0;
            end
            check_status();
            if (op_done !== 0 || fault !== 0 || data_out !== 0 ||
                pre_node_addr !== MAX_NODE || next_node_addr !== MAX_NODE)
                $fatal(1, "Reset did not clear outputs");
            @(negedge clk);
        end
    endtask

    task automatic command(
        input integer operation,
        input [ADDR_WIDTH-1:0] address,
        input [DATA_WIDTH-1:0] value,
        input integer drive_mode = 0
    );
        integer item, candidate, position, allocated, cycle, cycle_limit, index_bound;
        reg expected_fault, occupied, completed;
        reg [DATA_WIDTH-1:0] expected_data;
        reg [ADDR_WIDTH-1:0] expected_previous, expected_next;
        begin
            position = -1;
            allocated = MAX_NODE;
            expected_fault = 0;
            expected_data = data_out;
            expected_previous = pre_node_addr;
            expected_next = next_node_addr;
            index_bound = 0;
            cycle_limit = (TB_TIMEOUT_CYCLES < MAX_NODE+4) ? TB_TIMEOUT_CYCLES : MAX_NODE+4;
            completed = 0;
            for (item = 0; item < count; item = item + 1)
                if (model_addr[item] == address)
                    position = item;
            case (operation)
                READ_ADDR: begin
                    expected_fault = (position < 0);
                    if (!expected_fault) begin
                        expected_data = model_data[position];
                        expected_previous = (BIDIRECTIONAL && position > 0) ? model_addr[position-1] : MAX_NODE;
                        expected_next = (position+1 < count) ? model_addr[position+1] : MAX_NODE;
                    end
                end
                INSERT_ADDR, INSERT_INDEX: begin
                    expected_fault = (count == MAX_NODE);
                    if (operation == INSERT_INDEX) begin
                        position = (address >= count) ? count : address;
                        if (address < count)
                            index_bound = ((address < count-1-address) ? address : count-1-address) + 4;
                    end
                    else if (address >= MAX_NODE)
                        position = count;
                    else if (position < 0)
                        expected_fault = 1;
                    for (candidate = 0; candidate < MAX_NODE; candidate = candidate + 1) begin
                        occupied = 0;
                        for (item = 0; item < count; item = item + 1)
                            if (model_addr[item] == candidate)
                                occupied = 1;
                        if (!occupied && allocated == MAX_NODE)
                            allocated = candidate;
                    end
                end
                DELETE_VALUE: begin
                    position = -1;
                    for (item = 0; item < count; item = item + 1)
                        if (model_data[item] == value && position < 0)
                            position = item;
                    expected_fault = (position < 0);
                end
                DELETE_ADDR: expected_fault = (position < 0);
                DELETE_INDEX: begin
                    position = address;
                    expected_fault = (address >= count);
                    if (!expected_fault)
                        index_bound = ((address < count-1-address) ? address : count-1-address) + 4;
                end
                default: expected_fault = 1;
            endcase
            if (op_done !== 0)
                $fatal(1, "Previous operation did not finish");
            @(negedge clk);
            op = operation;
            addr_in = address;
            data_in = value;
            op_start = 1;
            cycle = 0;
            while (cycle < cycle_limit && !completed) begin
                @(posedge clk);
                #1;
                if (op_done === 1) begin
                    completed = 1;
                    if (fault !== expected_fault)
                        $fatal(1, "Operation %0d at %0d: fault %0d, expected %0d",
                               operation, address, fault, expected_fault);
                    if (data_out !== expected_data || pre_node_addr !== expected_previous ||
                        next_node_addr !== expected_next)
                        $fatal(1, "Read outputs: got %0d/%0d/%0d, expected %0d/%0d/%0d",
                               data_out, pre_node_addr, next_node_addr,
                               expected_data, expected_previous, expected_next);
                end else begin
                    if (fault !== 0)
                        $fatal(1, "Fault asserted before completion");
                    check_status(); // Mutations must become visible atomically at completion.
                    @(negedge clk);
                    // 0: one-cycle pulse, 1: unrelated request while busy, 2: held command.
                    op_start = (drive_mode != 0);
                    if (drive_mode != 2) begin
                        op = INSERT_INDEX;
                        addr_in = 0;
                        data_in = ~value;
                    end
                end
                cycle = cycle + 1;
            end
            if (!completed)
                $fatal(1, "Operation %0d timed out", operation);
            if (BIDIRECTIONAL && !expected_fault && index_bound != 0 && cycle > index_bound)
                $fatal(1, "DLL indexed access did not start at the nearer end");
            if (!expected_fault) begin
                case (operation)
                    INSERT_ADDR, INSERT_INDEX: begin
                        for (item = MAX_NODE-1; item > 0; item = item - 1)
                            if (item > position) begin
                                model_addr[item] = model_addr[item-1];
                                model_data[item] = model_data[item-1];
                            end
                        model_addr[position] = allocated;
                        model_data[position] = value;
                        count = count + 1;
                    end
                    DELETE_VALUE, DELETE_ADDR, DELETE_INDEX: begin
                        for (item = 0; item < MAX_NODE-1; item = item + 1)
                            if (item >= position) begin
                                model_addr[item] = model_addr[item+1];
                                model_data[item] = model_data[item+1];
                            end
                        count = count - 1;
                        model_addr[count] = MAX_NODE;
                        model_data[count] = 0;
                    end
                endcase
            end
            check_status();
            transactions = transactions + 1;
            @(negedge clk);
            op_start = 0;
            @(posedge clk);
            #1;
            if (op_done !== 0 || fault !== 0)
                $fatal(1, "Completion flags did not clear after one cycle");
            @(negedge clk);
        end
    endtask

    task automatic check_list;
        integer address;
        begin
            check_status();
            for (address = 0; address <= MAX_NODE; address = address + 1)
                command(READ_ADDR, address, 0);
            if (MAX_ADDR > MAX_NODE)
                command(READ_ADDR, MAX_ADDR, 0);
        end
    endtask

    task automatic fill_zero;
        integer item;
        begin
            for (item = 0; item < MAX_NODE; item = item + 1)
                command(INSERT_INDEX, MAX_NODE, 0);
        end
    endtask

    task automatic empty_tests;
        begin
            reset_dut();
            command(READ_ADDR, 0, 0);
            command(DELETE_VALUE, 0, 0);
            command(DELETE_ADDR, 0, 0);
            command(DELETE_INDEX, 0, 0);
            command(4, 0, 0);
            command(6, 0, 0);
            command(INSERT_ADDR, 0, 0);
            command(READ_ADDR, MAX_NODE, 0);
            command(INSERT_ADDR, MAX_NODE, MAX_DATA);
            check_list();
            command(DELETE_INDEX, MAX_ADDR, 0);
            command(DELETE_ADDR, MAX_ADDR, 0);
            command(4, MAX_ADDR, 0);
            command(6, MAX_ADDR, 0);
            check_list();
        end
    endtask

    task automatic singleton_tests;
        integer method;
        begin
            reset_dut();
            for (method = 0; method < 3; method = method + 1) begin
                command(INSERT_INDEX, 0, MAX_DATA);
                check_list();
                repeat (3) command(READ_ADDR, 0, 0);
                if (pre_node_addr !== MAX_NODE || next_node_addr !== MAX_NODE)
                    $fatal(1, "Singleton endpoints must both terminate at NULL");
                case (method)
                    0: command(DELETE_INDEX, 0, MAX_DATA);
                    1: command(DELETE_ADDR, 0, MAX_DATA);
                    2: command(DELETE_VALUE, 0, MAX_DATA);
                endcase
                check_list();
            end
        end
    endtask

    task automatic insert_tests;
        integer item;
        begin
            reset_dut();
            for (item = 0; item < MAX_NODE; item = item + 1) begin
                case (item % 4)
                    0: command(INSERT_INDEX, MAX_ADDR, item);
                    1: command(INSERT_ADDR, model_addr[0], item);
                    2: command(INSERT_INDEX, count/2, item);
                    3: command(INSERT_ADDR, model_addr[count-1], item);
                endcase
                check_list();
            end
            command(INSERT_ADDR, MAX_NODE, 7);
            command(INSERT_ADDR, model_addr[0], 7);
            command(INSERT_INDEX, 0, 7);
            command(INSERT_INDEX, MAX_ADDR, 7);
            check_list();
        end
    endtask

    task automatic delete_tests;
        integer item;
        begin
            reset_dut();
            fill_zero();
            command(DELETE_VALUE, 0, MAX_DATA);
            check_list();
            for (item = 0; item < MAX_NODE; item = item + 1) begin
                case (item % 4)
                    0: command(DELETE_VALUE, 0, 0);
                    1: command(DELETE_ADDR, model_addr[count-1], 0);
                    2: command(DELETE_INDEX, count/2, 0);
                    3: command(DELETE_ADDR, model_addr[0], 0);
                endcase
                check_list();
            end
            command(DELETE_VALUE, 0, 0);
            check_list();
        end
    endtask

    task automatic reuse_tests;
        integer trial, removed;
        begin
            reset_dut();
            fill_zero();
            for (trial = 0; trial < MAX_NODE+2; trial = trial + 1) begin
                removed = model_addr[count/2];
                command(DELETE_ADDR, removed, 0);
                command(READ_ADDR, removed, 0);
                command(INSERT_ADDR, removed, 1);
                command(INSERT_INDEX, 0, trial);
                if (model_addr[0] != removed)
                    $fatal(1, "Lowest free address was not reused");
                check_list();
            end
        end
    endtask

    task automatic traversal_tests;
        integer item, direction, traversal, position, address;
        begin
            reset_dut();
            for (item = 0; item < MAX_NODE; item = item + 1)
                command(INSERT_INDEX, MAX_NODE, item, 1);
            check_list();
            for (direction = 0; direction < 1+BIDIRECTIONAL; direction = direction + 1) begin
                for (traversal = 0; traversal < 2; traversal = traversal + 1) begin
                    address = direction ? model_addr[count-1] : model_addr[0];
                    for (item = 0; item < count; item = item + 1) begin
                        position = direction ? count-1-item : item;
                        if (address != model_addr[position])
                            $fatal(1, "Traversal visited the wrong address");
                        command(READ_ADDR, address, 0, 1);
                        address = direction ? pre_node_addr : next_node_addr;
                    end
                    if (address != MAX_NODE)
                        $fatal(1, "Linear traversal must terminate at NULL");
                end
            end
            command(DELETE_INDEX, count-1, 0, 1);
            command(INSERT_INDEX, 0, MAX_DATA, 1);
            command(DELETE_VALUE, 0, MAX_DATA, 1);
            check_list();
        end
    endtask

    task automatic random_tests;
        integer trial, operation, position;
        reg [ADDR_WIDTH-1:0] address;
        reg [DATA_WIDTH-1:0] value;
        begin
            reset_dut();
            for (trial = 0; trial < 200; trial = trial + 1) begin
                operation = $urandom_range(0, 7);
                address = $urandom_range(0, MAX_ADDR);
                value = {$urandom, $urandom};
                if (count != 0 && $urandom_range(0, 1)) begin
                    position = $urandom_range(0, count-1);
                    address = model_addr[position];
                    if (operation == DELETE_VALUE)
                        value = model_data[position];
                end
                command(operation, address, value, trial % 3);
                check_list();
            end
        end
    endtask

    task automatic reset_tests;
        integer method, wait_cycle;
        begin
            for (method = 0; method < 3; method = method + 1) begin
                reset_dut();
                if (method != 0) fill_zero();
                @(negedge clk);
                case (method)
                    0: op = INSERT_INDEX;
                    1: op = DELETE_INDEX;
                    2: op = DELETE_VALUE;
                endcase
                addr_in = MAX_NODE-1;
                data_in = MAX_DATA;
                op_start = 1;
                @(posedge clk);
                #1;
                if (op_done !== 0)
                    $fatal(1, "Operation completed too soon before reset");
                if (method == 2)
                    for (wait_cycle = 0; wait_cycle < MAX_NODE; wait_cycle = wait_cycle + 1) begin
                        @(negedge clk);
                        op_start = 0;
                        @(posedge clk);
                        #1;
                        if (op_done !== 0)
                            $fatal(1, "Missing-value walk ended too early");
                    end
                reset_dut();
                repeat (MAX_NODE+5) begin
                    @(posedge clk);
                    #1;
                    if (op_done !== 0 || fault !== 0)
                        $fatal(1, "Aborted operation completed after reset");
                end
                check_list();
                command(INSERT_INDEX, 0, 1);
                command(DELETE_INDEX, 0, 0);
            end
        end
    endtask

    task automatic output_tests;
        begin
            reset_dut();
            command(INSERT_INDEX, 0, MAX_DATA);
            command(READ_ADDR, 0, 0);
            command(DELETE_INDEX, 0, 0);
            command(READ_ADDR, 0, 0);
            command(INSERT_INDEX, 0, 0);
            command(4, 0, 0);
            command(READ_ADDR, 0, 0);
        end
    endtask

    task automatic held_tests;
        integer item;
        begin
            reset_dut();
            for (item = 0; item < MAX_NODE; item = item + 1)
                command(INSERT_INDEX, MAX_NODE, item, 2);
            command(DELETE_VALUE, 0, model_data[count-1], 2);
            repeat (MAX_NODE+3) begin
                @(posedge clk);
                #1;
                if (op_done !== 0 || fault !== 0)
                    $fatal(1, "Held-start command completed twice");
                check_status();
            end
            check_list();
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
        if (!$value$plusargs("TEST=%s", test_name)) test_name = "all";
        if (test_name == "all" || test_name == "empty") empty_tests();
        if (test_name == "all" || test_name == "singleton") singleton_tests();
        if (test_name == "all" || test_name == "insert") insert_tests();
        if (test_name == "all" || test_name == "delete") delete_tests();
        if (test_name == "all" || test_name == "reuse") reuse_tests();
        if (test_name == "all" || test_name == "traversal") traversal_tests();
        if (test_name == "all" || test_name == "random") random_tests();
        if (test_name == "all" || test_name == "reset") reset_tests();
        if (test_name == "all" || test_name == "outputs") output_tests();
        if (test_name == "all" || test_name == "held") held_tests();
        if (transactions == 0) $fatal(1, "Unknown TEST selector: %s", test_name);
        $display("ALL TESTS PASSED: %0d transactions", transactions);
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Global simulation timeout");
    end
endmodule
