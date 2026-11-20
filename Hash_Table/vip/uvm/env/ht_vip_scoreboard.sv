//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ht_vip_scoreboard)

    int checked_transactions;

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
        int bucket, occupancy;
        bit expected_error;
        bit [31:0] expected_value;
        if (item.reset_seen) begin
            hash_table.delete();
            return;
        end
        checked_transactions++;
        bucket = item.key % cfg.TOTAL_INDEX;
        occupancy = 0;
        foreach (hash_table[key]) if (key % cfg.TOTAL_INDEX == bucket) occupancy++;
        expected_error = 0;
        expected_value = 0;
        case (item.op)
            INSERT: begin
                expected_error = !hash_table.exists(item.key) && occupancy == cfg.CHAINING_SIZE;
                if (!expected_error) begin
                    if (!hash_table.exists(item.key)) occupancy++;
                    hash_table[item.key] = item.value;
                end
            end
            DELETE: begin
                expected_error = !hash_table.exists(item.key);
                if (!expected_error) begin
                    hash_table.delete(item.key);
                    occupancy--;
                end
            end
            SEARCH: begin
                expected_error = !hash_table.exists(item.key);
                if (!expected_error) expected_value = hash_table[item.key];
            end
            default: begin
                expected_error = 1;
                occupancy = 0;
            end
        endcase
        if (item.op_error != expected_error || item.result_value != expected_value || item.collision_count != occupancy)
            `uvm_error("SCOREBOARD", $sformatf("%s key=%0h expected error/value/count=%0b/%0h/%0d actual=%0b/%0h/%0d", item.op.name(), item.key, expected_error, expected_value, occupancy, item.op_error, item.result_value, item.collision_count))
    endfunction

    function void report_phase(uvm_phase phase);
        if (checked_transactions == 0)
            `uvm_fatal("EMPTY_TEST", "No completed transactions checked")
        `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked_transactions), UVM_LOW)
    endfunction
endclass
