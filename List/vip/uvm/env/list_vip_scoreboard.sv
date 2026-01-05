//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_scoreboard
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Scoreboard for List VIP - self-checking component with list model
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(list_vip_scoreboard)

    uvm_analysis_imp #(list_vip_seq_item, list_vip_scoreboard) imp;

    list_vip_config cfg;
    int list_model[$];  // Queue to model the list
    int error_count;
    int insert_count;
    int delete_count;
    int read_count;
    int search_count;
    int sort_count;
    int sum_count;

    function new(string name = "list_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(list_vip_config)::get(this, "", "list_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")
    endfunction

    function void write(list_vip_seq_item item);
        case (item.op)
            READ: check_read(item);
            INSERT: check_insert(item);
            DELETE: check_delete(item);
            FIND_1ST: check_find_1st(item);
            FIND_ALL: check_find_all(item);
            SUM: check_sum(item);
            SORT_ASC: check_sort_asc(item);
            SORT_DES: check_sort_des(item);
        endcase

        // Check length
        if (item.current_len != list_model.size()) begin
            `uvm_error("SCOREBOARD", $sformatf("Length mismatch! Expected=%0d Actual=%0d", list_model.size(), item.current_len))
            error_count++;
        end
    endfunction

    function void check_read(list_vip_seq_item item);
        read_count++;

        if (item.index >= list_model.size()) begin
            // Out of bounds read
            if (!item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("READ[%0d]: Should error (out of bounds) but didn't", item.index))
                error_count++;
            end
        end else begin
            // Valid read
            if (item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("READ[%0d]: Should not error", item.index))
                error_count++;
            end
            if (item.result_data != list_model[item.index]) begin
                `uvm_error("SCOREBOARD", $sformatf("READ[%0d]: Data mismatch! Expected=0x%0h Actual=0x%0h",
                           item.index, list_model[item.index], item.result_data))
                error_count++;
            end else begin
                `uvm_info("SCOREBOARD", $sformatf("READ[%0d]: data=0x%0h MATCH", item.index, item.result_data), UVM_MEDIUM)
            end
        end
    endfunction

    function void check_insert(list_vip_seq_item item);
        insert_count++;

        if (list_model.size() >= cfg.LENGTH) begin
            // List full
            if (!item.op_error) begin
                `uvm_error("SCOREBOARD", "INSERT: Should error (list full) but didn't")
                error_count++;
            end
        end else begin
            // Valid insert
            if (item.op_error) begin
                `uvm_error("SCOREBOARD", "INSERT: Should not error")
                error_count++;
            end

            if (item.index >= list_model.size()) begin
                // Append at end
                list_model.push_back(item.data);
            end else begin
                // Insert at index
                list_model.insert(item.index, item.data);
            end
            `uvm_info("SCOREBOARD", $sformatf("INSERT[%0d]: data=0x%0h len=%0d", item.index, item.data, list_model.size()), UVM_MEDIUM)
        end
    endfunction

    function void check_delete(list_vip_seq_item item);
        delete_count++;

        if (item.index >= list_model.size()) begin
            // Out of bounds delete
            if (!item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("DELETE[%0d]: Should error (out of bounds) but didn't", item.index))
                error_count++;
            end
        end else begin
            // Valid delete
            if (item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("DELETE[%0d]: Should not error", item.index))
                error_count++;
            end
            list_model.delete(item.index);
            `uvm_info("SCOREBOARD", $sformatf("DELETE[%0d]: len=%0d", item.index, list_model.size()), UVM_MEDIUM)
        end
    endfunction

    function void check_find_1st(list_vip_seq_item item);
        int found_idx = -1;
        search_count++;

        // Search for first occurrence
        for (int i = 0; i < list_model.size(); i++) begin
            if (list_model[i] == item.data) begin
                found_idx = i;
                break;
            end
        end

        if (found_idx == -1) begin
            // Not found
            if (!item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("FIND_1ST(0x%0h): Should error (not found) but didn't", item.data))
                error_count++;
            end
        end else begin
            // Found
            if (item.op_error) begin
                `uvm_error("SCOREBOARD", $sformatf("FIND_1ST(0x%0h): Should not error", item.data))
                error_count++;
            end
            if (item.result_data != found_idx) begin
                `uvm_error("SCOREBOARD", $sformatf("FIND_1ST(0x%0h): Index mismatch! Expected=%0d Actual=%0d",
                           item.data, found_idx, item.result_data))
                error_count++;
            end else begin
                `uvm_info("SCOREBOARD", $sformatf("FIND_1ST(0x%0h): index=%0d MATCH", item.data, found_idx), UVM_MEDIUM)
            end
        end
    endfunction

    function void check_find_all(list_vip_seq_item item);
        // Note: Simplified check - full FIND_ALL requires tracking multiple results
        search_count++;
        `uvm_info("SCOREBOARD", $sformatf("FIND_ALL(0x%0h): Completed", item.data), UVM_MEDIUM)
    endfunction

    function void check_sum(list_vip_seq_item item);
        int expected_sum = 0;
        sum_count++;

        foreach (list_model[i]) begin
            expected_sum += list_model[i];
        end

        if (item.result_data != expected_sum) begin
            `uvm_error("SCOREBOARD", $sformatf("SUM: Mismatch! Expected=%0d Actual=%0d", expected_sum, item.result_data))
            error_count++;
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("SUM: result=%0d MATCH", expected_sum), UVM_MEDIUM)
        end
    endfunction

    function void check_sort_asc(list_vip_seq_item item);
        sort_count++;
        list_model.sort();
        `uvm_info("SCOREBOARD", "SORT_ASC: Updated model", UVM_MEDIUM)
    endfunction

    function void check_sort_des(list_vip_seq_item item);
        sort_count++;
        list_model.sort();
        list_model.reverse();
        `uvm_info("SCOREBOARD", "SORT_DES: Updated model", UVM_MEDIUM)
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Insert Count: %0d", insert_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Delete Count: %0d", delete_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Read Count: %0d", read_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Search Count: %0d", search_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Sort Count: %0d", sort_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Sum Count: %0d", sum_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Error Count: %0d", error_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final List Size: %0d", list_model.size()), UVM_LOW)
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)

        if (error_count > 0) begin
            `uvm_error("SCOREBOARD", $sformatf("Test FAILED with %0d errors", error_count))
        end else begin
            `uvm_info("SCOREBOARD", "Test PASSED - No errors detected", UVM_LOW)
        end
    endfunction

endclass
