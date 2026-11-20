//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(deff_vip_scoreboard)

    int checked_transactions;

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

    bit [7:0] expected;

    virtual function void write(deff_vip_seq_item item);
        bit [7:0] enables;
        if (item.reset_seen) expected = cfg.RESET_VALUE;
        else begin
            enables = item.rising_edge ? item.pos_edge_latch_en : item.neg_edge_latch_en;
            expected = (expected & ~enables) | (item.data_in & enables);
            if (enables != 0) checked_transactions++;
        end
        if (item.data_out !== expected)
            `uvm_error("SCOREBOARD", $sformatf("Edge=%0b expected=%0h actual=%0h", item.rising_edge, expected, item.data_out))
    endfunction

    function void report_phase(uvm_phase phase);
        if (checked_transactions == 0)
            `uvm_fatal("EMPTY_TEST", "No enabled edges checked")
        `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked_transactions), UVM_LOW)
    endfunction
endclass
