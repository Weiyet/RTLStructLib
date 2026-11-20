//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_monitor
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Monitor for LIFO VIP - observes DUT signals
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_monitor extends uvm_monitor;
    `uvm_component_utils(lifo_vip_monitor)

    virtual lifo_vip_if vif;
    lifo_vip_config cfg;
    uvm_analysis_port #(lifo_vip_seq_item) ap;

    function new(string name = "lifo_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual lifo_vip_if)::get(this, "", "lifo_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(lifo_vip_config)::get(this, "", "lifo_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        lifo_vip_seq_item item;
        forever begin
            @(posedge vif.clk);
            item = lifo_vip_seq_item::type_id::create("cycle");
            item.reset_seen = vif.rst;
            item.op = vif.wr_en ? PUSH : (vif.rd_en ? POP : IDLE);
            item.bypass = vif.wr_en && vif.rd_en;
            item.data = vif.data_wr;
            item.success = item.bypass || (item.op == PUSH ? !vif.lifo_full : !vif.lifo_empty);
            #1ns;
            item.read_data = vif.data_rd;
            item.full = vif.lifo_full;
            item.empty = vif.lifo_empty;
            ap.write(item);
        end
    endtask

endclass
