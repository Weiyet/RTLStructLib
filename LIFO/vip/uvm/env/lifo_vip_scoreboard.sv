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

    function void write(lifo_vip_seq_item item);
        case (item.op)
            PUSH: check_push(item);
            POP: check_pop(item);
        endcase
    endfunction

    function void check_push(lifo_vip_seq_item item);
        if (item.success) begin
            // Successful push - add to model
            expected_queue.push_back(item.data);
            push_count++;
            `uvm_info("SCOREBOARD", $sformatf("PUSH: data=0x%0h depth=%0d", item.data, expected_queue.size()), UVM_MEDIUM)

            // Check full flag
            if (expected_queue.size() == cfg.DEPTH && !item.full) begin
                `uvm_error("SCOREBOARD", $sformatf("LIFO should be full but full flag not set. Depth=%0d", expected_queue.size()))
                error_count++;
            end
        end else begin
            // Failed push due to full LIFO
            if (!item.full) begin
                `uvm_error("SCOREBOARD", "Push failed but full flag not set")
                error_count++;
            end
            `uvm_info("SCOREBOARD", "PUSH failed - LIFO full", UVM_MEDIUM)
        end
    endfunction

    function void check_pop(lifo_vip_seq_item item);
        int expected_data;

        if (item.success) begin
            // Successful pop - check data
            if (expected_queue.size() == 0) begin
                `uvm_error("SCOREBOARD", "Pop succeeded but model is empty")
                error_count++;
                return;
            end

            expected_data = expected_queue.pop_back(); // LIFO: pop from back
            pop_count++;

            if (item.read_data != expected_data) begin
                `uvm_error("SCOREBOARD", $sformatf("Data mismatch! Expected=0x%0h Actual=0x%0h", expected_data, item.read_data))
                error_count++;
            end else begin
                `uvm_info("SCOREBOARD", $sformatf("POP: data=0x%0h depth=%0d MATCH", item.read_data, expected_queue.size()), UVM_MEDIUM)
            end

            // Check empty flag
            if (expected_queue.size() == 0 && !item.empty) begin
                `uvm_error("SCOREBOARD", "LIFO should be empty but empty flag not set")
                error_count++;
            end
        end else begin
            // Failed pop due to empty LIFO
            if (!item.empty) begin
                `uvm_error("SCOREBOARD", "Pop failed but empty flag not set")
                error_count++;
            end
            `uvm_info("SCOREBOARD", "POP failed - LIFO empty", UVM_MEDIUM)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Push Count: %0d", push_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Pop Count: %0d", pop_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Error Count: %0d", error_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final Queue Depth: %0d", expected_queue.size()), UVM_LOW)
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)

        if (error_count > 0) begin
            `uvm_error("SCOREBOARD", $sformatf("Test FAILED with %0d errors", error_count))
        end else begin
            `uvm_info("SCOREBOARD", "Test PASSED - No errors detected", UVM_LOW)
        end
    endfunction

endclass
