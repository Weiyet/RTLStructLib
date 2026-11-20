//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class table_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(table_vip_scoreboard)

    int checked_transactions;

    uvm_analysis_imp #(table_vip_seq_item, table_vip_scoreboard) analysis_export;
    table_vip_config cfg;

    // Reference model: array to track table contents
    bit [7:0] table_model[32];
    int write_count;
    int read_count;

    function new(string name = "table_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        write_count = 0;
        read_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(table_vip_config)::get(this, "", "table_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")

        // Initialize table model
        for (int i = 0; i < 32; i++) begin
            table_model[i] = 8'h00;
        end
    endfunction

    bit [7:0] last_read[2];

    virtual function void write(table_vip_seq_item item);
        if (item.reset_seen) begin
            foreach (table_model[i]) table_model[i] = 0;
            foreach (last_read[i]) last_read[i] = 0;
        end else begin
            if (item.wr_en != 0 || item.rd_en) checked_transactions++;
            // Applying writes in port order implements highest-port priority.
            for (int port = 0; port < 2; port++)
                if (item.wr_en[port]) table_model[item.index_wr[port]] = item.data_wr[port];
            if (item.rd_en)
                for (int port = 0; port < 2; port++) last_read[port] = table_model[item.index_rd[port]];
        end
        foreach (last_read[port])
            if (item.data_rd[port] !== last_read[port])
                `uvm_error("READ", $sformatf("Port %0d expected=%0h actual=%0h", port, last_read[port], item.data_rd[port]))
    endfunction

    function void report_phase(uvm_phase phase);
        if (checked_transactions == 0)
            `uvm_fatal("EMPTY_TEST", "No enabled transactions checked")
        `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked_transactions), UVM_LOW)
    endfunction
endclass
