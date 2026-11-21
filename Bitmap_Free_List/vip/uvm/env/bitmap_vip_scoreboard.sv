class bitmap_vip_scoreboard extends uvm_subscriber #(bitmap_vip_seq_item);
    `uvm_component_utils(bitmap_vip_scoreboard)
    // Ownership is an ordered set of allocated IDs, not a copy of the RTL bitmap.
    bit owned[int];
    bit reset_seen;
    int checked, resets;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void write(bitmap_vip_seq_item s);
        bit a_ok, f_ok;
        int selected, available;
        a_ok = 0; f_ok = 0; selected = 0;
        if (s.rst) begin
            owned.delete(); reset_seen = 1; resets++;
        end else begin
            if (!reset_seen) `uvm_fatal("RESET", "Observe reset before traffic")
            if (s.free_req && owned.exists(int'(s.free_id))) begin
                f_ok = 1; owned.delete(int'(s.free_id));
            end
            if (s.alloc_req && owned.num() < CAPACITY) begin
                a_ok = 1;
                while (owned.exists(selected)) selected++;
                owned[selected] = 1;
            end
            if (s.alloc_req || s.free_req) checked++;
        end
        available = CAPACITY - owned.num();
        if (s.alloc_valid !== a_ok || s.free_valid !== f_ok ||
            s.alloc_error !== (s.alloc_req && !a_ok && !s.rst) ||
            s.free_error !== (s.free_req && !f_ok && !s.rst) ||
            s.alloc_id !== ID_WIDTH'(selected) ||
            s.free_count !== COUNT_WIDTH'(available) ||
            s.exhausted !== (available == 0) || s.all_free !== (available == CAPACITY))
            `uvm_error("MODEL", $sformatf("Expected alloc=%0b id=%0d free=%0b count=%0d; got alloc=%0b id=%0d free=%0b count=%0d", a_ok, selected, f_ok, available, s.alloc_valid, s.alloc_id, s.free_valid, s.free_count))
    endfunction
    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        server = uvm_report_server::get_server();
        if (!reset_seen || checked == 0) `uvm_fatal("EMPTY_TEST", "No checked traffic after reset")
        if (server.get_severity_count(UVM_ERROR) == 0 && server.get_severity_count(UVM_FATAL) == 0)
            `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked), UVM_LOW)
    endfunction
endclass
