//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(deff_vip_scoreboard)

    uvm_analysis_imp #(deff_vip_seq_item, deff_vip_scoreboard) analysis_export;
    deff_vip_config cfg;

    // Reference model: track current FF state
    bit [7:0] q_out_pos;
    bit [7:0] q_out_neg;
    int transaction_count;

    function new(string name = "deff_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        q_out_pos = 8'h00;
        q_out_neg = 8'h00;
        transaction_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(deff_vip_config)::get(this, "", "deff_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")

        // Initialize with reset value
        q_out_pos = cfg.RESET_VALUE;
    endfunction

    virtual function void write(deff_vip_seq_item item);
        bit [7:0] expected_data_out;
        bit [7:0] d_in_pos;
        bit [7:0] d_in_neg;

        transaction_count++;

        `uvm_info("SCOREBOARD", $sformatf("Checking: %s", item.convert2string()), UVM_MEDIUM)

        // Model the dual-edge FF behavior
        // For each bit, update based on latch enables
        for (int i = 0; i < 8; i++) begin
            // Positive edge logic
            d_in_pos[i] = item.data_in[i] ^ q_out_neg[i];
            if (item.pos_edge_latch_en[i]) begin
                q_out_pos[i] = d_in_pos[i];
            end

            // Negative edge logic (happens in same cycle)
            d_in_neg[i] = item.data_in[i] ^ q_out_pos[i];
            if (item.neg_edge_latch_en[i]) begin
                q_out_neg[i] = d_in_neg[i];
            end

            // Output is XOR of both registers
            expected_data_out[i] = q_out_pos[i] ^ q_out_neg[i];
        end

        // Check output
        if (item.data_out != expected_data_out) begin
            `uvm_error("SCOREBOARD", $sformatf("Data mismatch: expected=0x%0h actual=0x%0h (pos_en=0x%0h neg_en=0x%0h)",
                      expected_data_out, item.data_out, item.pos_edge_latch_en, item.neg_edge_latch_en))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("Data matched: 0x%0h", item.data_out), UVM_HIGH)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("\n\n=== Dual Edge FF Statistics ==="), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Transactions: %0d", transaction_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final q_out_pos: 0x%0h", q_out_pos), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final q_out_neg: 0x%0h", q_out_neg), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final data_out: 0x%0h", q_out_pos ^ q_out_neg), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("===============================\n"), UVM_LOW)
    endfunction

endclass
