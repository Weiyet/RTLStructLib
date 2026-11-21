`timescale 1ns/1ps
module tb;
    parameter CAPACITY = 16;
    parameter TB_TIMEOUT_CYCLES = 20000;
    localparam ID_WIDTH = (CAPACITY <= 1) ? 1 : $clog2(CAPACITY);
    localparam COUNT_WIDTH = (CAPACITY < 1) ? 1 : $clog2(CAPACITY+1);
    reg clk = 0, rst = 1, alloc_req = 0, free_req = 0;
    reg [ID_WIDTH-1:0] free_id = 0;
    wire alloc_valid, alloc_error, free_valid, free_error, exhausted, all_free;
    wire [ID_WIDTH-1:0] alloc_id;
    wire [COUNT_WIDTH-1:0] free_count;
`ifdef BITMAP_FREE_LIST_NETLIST
    bitmap_free_list dut (.*);
`else
    bitmap_free_list #(.CAPACITY(CAPACITY)) dut (.*);
`endif
    always #5 clk = ~clk;
    bit occupied [0:CAPACITY-1];
    integer cycles = 0, checked = 0, seed, dummy, i, j, n;
    reg [31:0] random_value;
    string wave_file;

    always @(posedge clk) begin
        cycles = cycles + 1;
        if (cycles > TB_TIMEOUT_CYCLES) $fatal(1, "Free List watchdog");
    end

    task step(input bit allocate, input bit release_id, input integer id,
              input bit reset_now);
        integer selected, available, k, pin_id;
        bit release_ok, allocate_ok;
        begin
            @(negedge clk);
            rst = reset_now;
            alloc_req = allocate;
            free_req = release_id;
            free_id = ID_WIDTH'(id);
            pin_id = int'({1'b0, free_id});
            @(posedge clk);
            selected = -1;
            release_ok = 0;
            allocate_ok = 0;
            if (reset_now) begin
                for (k = 0; k < CAPACITY; k = k + 1) occupied[k] = 0;
            end else begin
                if (release_id && pin_id < CAPACITY) begin
                    release_ok = occupied[pin_id];
                    if (release_ok) occupied[pin_id] = 0;
                end
                if (allocate) begin
                    for (k = CAPACITY-1; k >= 0; k = k - 1)
                        if (!occupied[k]) selected = k;
                    if (selected >= 0) begin
                        allocate_ok = 1;
                        occupied[selected] = 1;
                    end
                end
            end
            available = 0;
            for (k = 0; k < CAPACITY; k = k + 1)
                if (!occupied[k]) available = available + 1;
            #1;
            if (alloc_valid !== allocate_ok || free_valid !== release_ok ||
                alloc_error !== (allocate && !allocate_ok && !reset_now) ||
                free_error !== (release_id && !release_ok && !reset_now))
                $fatal(1, "response mismatch cycle=%0d alloc=%b free=%b id=%0d", cycles, allocate, release_id, pin_id);
            if (alloc_id !== ID_WIDTH'(allocate_ok ? selected : 0))
                $fatal(1, "allocation ID mismatch cycle=%0d expected=%0d actual=%0d", cycles, selected, alloc_id);
            if (free_count !== COUNT_WIDTH'(available) ||
                exhausted !== (available == 0) || all_free !== (available == CAPACITY))
                $fatal(1, "occupancy mismatch cycle=%0d expected=%0d actual=%0d", cycles, available, free_count);
            checked = checked + 1;
        end
    endtask

    initial begin
        seed = 123;
        dummy = $value$plusargs("SEED=%d", seed);
        dummy = $urandom(seed);
        if ($value$plusargs("VCDFILE=%s", wave_file)) begin
            $dumpfile(wave_file);
            $dumpvars(0, tb);
        end
        step(1, 1, 0, 1); // Reset overrides both operations.
        step(0, 0, 0, 0);
        step(0, 1, 0, 0); // Duplicate release while all free.
        step(1, 1, 0, 0); // Illegal release does not cancel allocation.
        step(0, 1, 0, 0);
        for (j = 0; j < 3; j = j + 1) begin
            for (i = 0; i < CAPACITY; i = i + 1) step(1, 0, 0, 0);
            step(1, 0, 0, 0); // Exhaustion.
            for (i = CAPACITY-1; i >= 0; i = i - 1)
                step(1, 1, i, 0); // Reuse while exhausted.
            for (i = CAPACITY-1; i >= 0; i = i - 1) begin
                step(0, 1, i, 0);
                step(0, 1, i, 0); // Double free must preserve state.
            end
        end
        // Test every unused encoding for non-power-of-two capacities (also CAPACITY=1).
        for (i = CAPACITY; i < (2**ID_WIDTH); i = i + 1) begin
            step(0, 1, i, 0);
            step(1, 1, i, 0);
        end
        step(1, 1, 0, 1);
        for (n = 0; n < 2000; n = n + 1) begin
            random_value = $urandom;
            step(random_value[0], random_value[1], int'(random_value >> 2), (n % 317) == 316);
        end
        step(0, 0, 0, 1);
        for (i = 0; i < CAPACITY+1; i = i + 1) step(1, 0, 0, 0);
        for (i = 0; i < CAPACITY; i = i + 1) step(0, 1, i, 0);
        step(0, 0, 0, 0);
        $display("BITMAP FREE LIST PASSED: %0d cycles CAPACITY=%0d", checked, CAPACITY);
        $finish;
    end
endmodule
