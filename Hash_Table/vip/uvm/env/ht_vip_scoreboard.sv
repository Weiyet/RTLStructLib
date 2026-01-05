//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ht_vip_scoreboard)

    uvm_analysis_imp #(ht_vip_seq_item, ht_vip_scoreboard) analysis_export;
    ht_vip_config cfg;

    // Reference model: associative array to track hash table
    // hash_table[key] = value
    bit [31:0] hash_table[bit [31:0]];
    int insert_count;
    int delete_count;
    int search_count;

    function new(string name = "ht_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        insert_count = 0;
        delete_count = 0;
        search_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(ht_vip_config)::get(this, "", "ht_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")
    endfunction

    virtual function void write(ht_vip_seq_item item);
        `uvm_info("SCOREBOARD", $sformatf("Checking: %s", item.convert2string()), UVM_MEDIUM)

        case (item.op)
            INSERT: check_insert(item);
            DELETE: check_delete(item);
            SEARCH: check_search(item);
            default: `uvm_info("SCOREBOARD", "IDLE operation, no checking", UVM_HIGH)
        endcase
    endfunction

    function void check_insert(ht_vip_seq_item item);
        insert_count++;

        if (item.op_error) begin
            // Check if table is full
            if (hash_table.size() >= cfg.TOTAL_INDEX * cfg.CHAINING_SIZE) begin
                `uvm_info("SCOREBOARD", "Insert correctly failed - table full", UVM_MEDIUM)
            end else begin
                `uvm_warning("SCOREBOARD", $sformatf("Insert failed but table not full: size=%0d", hash_table.size()))
            end
        end else begin
            // Insert should succeed
            hash_table[item.key] = item.value;
            `uvm_info("SCOREBOARD", $sformatf("Inserted key=0x%0h value=0x%0h (total=%0d)",
                      item.key, item.value, hash_table.size()), UVM_HIGH)
        end
    endfunction

    function void check_delete(ht_vip_seq_item item);
        delete_count++;

        if (item.op_error) begin
            // Delete should fail if key not found
            if (!hash_table.exists(item.key)) begin
                `uvm_info("SCOREBOARD", $sformatf("Delete correctly failed - key 0x%0h not found", item.key), UVM_MEDIUM)
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("Delete failed but key 0x%0h exists in model", item.key))
            end
        end else begin
            // Delete should succeed
            if (hash_table.exists(item.key)) begin
                hash_table.delete(item.key);
                `uvm_info("SCOREBOARD", $sformatf("Deleted key=0x%0h (total=%0d)",
                          item.key, hash_table.size()), UVM_HIGH)
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("Delete succeeded but key 0x%0h not in model", item.key))
            end
        end
    endfunction

    function void check_search(ht_vip_seq_item item);
        search_count++;

        if (item.op_error) begin
            // Search should fail if key not found
            if (!hash_table.exists(item.key)) begin
                `uvm_info("SCOREBOARD", $sformatf("Search correctly failed - key 0x%0h not found", item.key), UVM_MEDIUM)
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("Search failed but key 0x%0h exists in model", item.key))
            end
        end else begin
            // Search should succeed and value should match
            if (hash_table.exists(item.key)) begin
                if (item.result_value == hash_table[item.key]) begin
                    `uvm_info("SCOREBOARD", $sformatf("Search matched: key=0x%0h value=0x%0h",
                              item.key, item.result_value), UVM_HIGH)
                end else begin
                    `uvm_error("SCOREBOARD", $sformatf("Search value mismatch: key=0x%0h expected=0x%0h actual=0x%0h",
                              item.key, hash_table[item.key], item.result_value))
                end
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("Search succeeded but key 0x%0h not in model", item.key))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("\n\n=== Hash Table Statistics ==="), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Inserts: %0d", insert_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Deletes: %0d", delete_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Searches: %0d", search_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final Hash Table Size: %0d", hash_table.size()), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("=============================\n"), UVM_LOW)
    endfunction

endclass
