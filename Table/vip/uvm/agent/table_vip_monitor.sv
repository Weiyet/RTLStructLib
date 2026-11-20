//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_monitor
//////////////////////////////////////////////////////////////////////////////////

class table_vip_monitor extends uvm_monitor;
    `uvm_component_utils(table_vip_monitor)

    virtual table_vip_if vif;
    table_vip_config cfg;
    uvm_analysis_port #(table_vip_seq_item) ap;

    function new(string name = "table_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual table_vip_if)::get(this, "", "table_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(table_vip_config)::get(this, "", "table_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        table_vip_seq_item item;
        forever begin
            @(posedge vif.clk);
            item = table_vip_seq_item::type_id::create("cycle");
            item.reset_seen = vif.rst;
            item.wr_en = vif.wr_en;
            item.rd_en = vif.rd_en;
            item.index_wr[0] = vif.index_wr[4:0];
            item.index_wr[1] = vif.index_wr[9:5];
            item.index_rd[0] = vif.index_rd[4:0];
            item.index_rd[1] = vif.index_rd[9:5];
            item.data_wr[0] = vif.data_wr[7:0];
            item.data_wr[1] = vif.data_wr[15:8];
            #1ns;
            item.data_rd[0] = vif.data_rd[7:0];
            item.data_rd[1] = vif.data_rd[15:8];
            ap.write(item);
        end
    endtask

endclass
