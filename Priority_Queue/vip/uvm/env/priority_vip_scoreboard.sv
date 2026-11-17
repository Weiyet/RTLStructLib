class priority_vip_scoreboard extends uvm_subscriber #(priority_vip_sample);
    `uvm_component_utils(priority_vip_scoreboard)
    pq_entry_t items[$];
    priority_vip_seq_item pending;
    bit expected_error, response_checked, reset_seen, stalled;
    logic [PRIORITY_WIDTH+DATA_WIDTH:0] held_response;
    pq_priority_t best;
    int occupancy = 0;
    int unsigned accepted = 0, completed = 0, aborted = 0, age = 0;
    int unsigned op_count[4], error_count[4], stalled_cycles = 0;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void check_condition(bit condition, string message);
        if (!condition) `uvm_fatal("SCOREBOARD", message)
    endfunction
    function void write(priority_vip_sample t);
        priority_vip_sample s;
        pq_entry_t entry;
        int match_index;
        s = t;
        if (s.rst === 1) begin
            reset_seen = 1;
            if (pending != null) aborted++;
            pending = null;
            items.delete();
            occupancy = 0;
            stalled = 0;
            check_condition(s.count === 0 && s.empty === 1 && s.full === 0, "Reset occupancy");
            check_condition(s.req_ready === 0 && s.rsp_valid === 0, "Reset handshake");
            check_condition({s.rsp_error, s.rsp_priority, s.rsp_data} === '0, "Reset response");
            return;
        end
        check_condition(reset_seen, "Observe reset before traffic");
        check_condition(!$isunknown({s.rst, s.req_valid, s.req_ready, s.rsp_valid, s.rsp_ready,
                                      s.count, s.full, s.empty}), "Unknown control signal");
        check_condition(s.count == occupancy && s.full == (occupancy == DEPTH) &&
                        s.empty == (occupancy == 0), "Occupancy mismatch");
        check_condition(s.req_ready == (pending == null), "Ready disagrees with outstanding command");
        if (stalled)
            check_condition(s.rsp_valid && {s.rsp_error, s.rsp_priority, s.rsp_data} === held_response,
                            "Response changed while stalled");
        stalled = s.rsp_valid && !s.rsp_ready;
        held_response = {s.rsp_error, s.rsp_priority, s.rsp_data};
        if (s.rsp_valid) begin
            check_condition(pending != null && !s.req_ready, "Unsolicited response");
            if (!response_checked) begin
                check_condition(s.rsp_error === expected_error, "Incorrect error response");
                if (expected_error || pending.op == 0)
                    check_condition({s.rsp_priority, s.rsp_data} === '0, "Nonzero acknowledgement");
                else begin
                    check_condition(s.rsp_priority === best, "Wrong priority");
                    match_index = -1;
                    foreach (items[i])
                        if (items[i].priority_value === s.rsp_priority && items[i].data === s.rsp_data)
                            match_index = i;
                    check_condition(match_index >= 0, "Unexpected payload");
                    if (pending.op == 1) items.delete(match_index);
                end
                response_checked = 1;
            end
            if (s.rsp_ready) begin
                completed++;
                pending = null;
            end else stalled_cycles++;
        end
        if (s.req_valid && s.req_ready) begin
            check_condition(pending == null && !s.rsp_valid, "Overlapping requests");
            check_condition(!$isunknown(s.req_op), "Unknown request opcode");
            if (s.req_op == 0 && occupancy < DEPTH)
                check_condition(!$isunknown({s.req_priority, s.req_data}), "Unknown push entry");
            pending = priority_vip_seq_item::type_id::create("observed_request");
            pending.op = s.req_op;
            expected_error = s.req_op == 3 || (s.req_op == 0 && occupancy == DEPTH) ||
                             ((s.req_op == 1 || s.req_op == 2) && occupancy == 0);
            best = '0;
            foreach (items[i])
                if (i == 0 || (MIN_FIRST ? items[i].priority_value < best : items[i].priority_value > best))
                    best = items[i].priority_value;
            response_checked = 0;
            age = 0;
            accepted++;
            op_count[s.req_op]++;
            if (expected_error) error_count[s.req_op]++;
            if (!expected_error && s.req_op == 0) begin
                entry.priority_value = s.req_priority;
                entry.data = s.req_data;
                items.push_back(entry);
                occupancy++;
            end else if (!expected_error && s.req_op == 1) occupancy--;
        end
        if (pending != null && !response_checked) begin
            age++;
            check_condition(age <= $clog2(DEPTH+1)+3, "Heap response timed out");
        end
    endfunction
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        check_condition(reset_seen && completed > 0, "No verified transactions");
        check_condition(pending == null, "Unfinished request");
        check_condition(accepted == completed + aborted, "Lost or duplicated transaction");
    endfunction
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", $sformatf("responses=%0d reset_aborts=%0d stalls=%0d ops=%p errors=%p",
                                       completed, aborted, stalled_cycles, op_count, error_count), UVM_LOW)
    endfunction
endclass
