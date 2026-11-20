//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_scoreboard
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Scoreboard for LIFO VIP - self-checking component
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(lifo_vip_scoreboard)

    int checked_transactions;

    uvm_analysis_imp #(lifo_vip_seq_item, lifo_vip_scoreboard) imp;

    lifo_vip_config cfg;
    int expected_queue[$];
    int push_count;
    int pop_count;
    int error_count;
    int bypass_count;

    function new(string name = "lifo_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(lifo_vip_config)::get(this, "", "lifo_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")
    endfunction

    int last_data;

    function void write(lifo_vip_seq_item item);
        bit expected_accept;
        if (item.reset_seen) begin
            expected_queue.delete();
            last_data = 0;
        end else if (item.op != IDLE) begin
            checked_transactions++;
            if (item.bypass) begin
                last_data = item.data;
                expected_accept = 1;
            end else if (item.op == PUSH) begin
                expected_accept = expected_queue.size() < cfg.DEPTH;
                if (expected_accept) expected_queue.push_back(item.data);
            end else begin
                expected_accept = expected_queue.size() > 0;
                if (expected_accept) last_data = expected_queue.pop_back();
            end
            if (item.success != expected_accept)
                `uvm_error("ACCEPT", "Full/empty incorrectly accepted or rejected an operation")
        end
        if (item.read_data != last_data || item.full != (expected_queue.size() == cfg.DEPTH) || item.empty != (expected_queue.size() == 0))
            `uvm_error("SCOREBOARD", $sformatf("Expected data/full/empty=%0h/%0b/%0b actual=%0h/%0b/%0b", last_data, expected_queue.size() == cfg.DEPTH, expected_queue.size() == 0, item.read_data, item.full, item.empty))
    endfunction

    function void report_phase(uvm_phase phase);
        if (checked_transactions == 0)
            `uvm_fatal("EMPTY_TEST", "No enabled transactions checked")
        `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked_transactions), UVM_LOW)
    endfunction
endclass
