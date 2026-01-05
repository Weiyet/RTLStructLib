//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class table_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(table_vip_scoreboard)

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

    virtual function void write(table_vip_seq_item item);
        `uvm_info("SCOREBOARD", $sformatf("Checking: %s", item.convert2string()), UVM_MEDIUM)

        case (item.op)
            WRITE: check_write(item);
            READ: check_read(item);
        endcase
    endfunction

    function void check_write(table_vip_seq_item item);
        write_count++;

        // Update model based on write enables
        if (item.wr_en[0]) begin
            table_model[item.index_wr[0]] = item.data_wr[0];
            `uvm_info("SCOREBOARD", $sformatf("Updated table[%0d] = 0x%0h",
                      item.index_wr[0], item.data_wr[0]), UVM_HIGH)
        end

        if (item.wr_en[1]) begin
            table_model[item.index_wr[1]] = item.data_wr[1];
            `uvm_info("SCOREBOARD", $sformatf("Updated table[%0d] = 0x%0h",
                      item.index_wr[1], item.data_wr[1]), UVM_HIGH)
        end
    endfunction

    function void check_read(table_vip_seq_item item);
        read_count++;

        // Check read data[0]
        if (item.data_rd[0] != table_model[item.index_rd[0]]) begin
            `uvm_error("SCOREBOARD", $sformatf("Read[0] mismatch at index %0d: expected=0x%0h actual=0x%0h",
                      item.index_rd[0], table_model[item.index_rd[0]], item.data_rd[0]))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("Read[0] matched: table[%0d] = 0x%0h",
                      item.index_rd[0], item.data_rd[0]), UVM_HIGH)
        end

        // Check read data[1]
        if (item.data_rd[1] != table_model[item.index_rd[1]]) begin
            `uvm_error("SCOREBOARD", $sformatf("Read[1] mismatch at index %0d: expected=0x%0h actual=0x%0h",
                      item.index_rd[1], table_model[item.index_rd[1]], item.data_rd[1]))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("Read[1] matched: table[%0d] = 0x%0h",
                      item.index_rd[1], item.data_rd[1]), UVM_HIGH)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("\n\n=== Table Statistics ==="), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Writes: %0d", write_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Reads: %0d", read_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("========================\n"), UVM_LOW)
    endfunction

endclass
