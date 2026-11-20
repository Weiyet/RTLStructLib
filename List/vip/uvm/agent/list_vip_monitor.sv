//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_monitor
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Monitor for List VIP - observes DUT signals
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_monitor extends uvm_monitor;
    `uvm_component_utils(list_vip_monitor)

    virtual list_vip_if vif;
    list_vip_config cfg;
    uvm_analysis_port #(list_vip_seq_item) ap;

    function new(string name = "list_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual list_vip_if)::get(this, "", "list_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(list_vip_config)::get(this, "", "list_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        list_vip_seq_item item;
        forever begin
            @(posedge vif.clk);
            if (vif.rst) begin
                item = list_vip_seq_item::type_id::create("reset");
                item.reset_seen = 1;
                ap.write(item);
                item = null;
                continue;
            end
            // Capture pins at acceptance, before nonblocking RTL updates.
            if (item == null && vif.op_en && !vif.op_done && !vif.op_in_progress) begin
                item = list_vip_seq_item::type_id::create("request");
                item.op = list_op_e'(vif.op_sel);
                item.data = vif.data_in;
                item.index = vif.index_in;
            end
            #1ns;
            if (item != null && vif.op_done && vif.op_in_progress)
                item.matched_indices.push_back(int'(vif.data_out));
            if (item != null && (vif.op_done && !vif.op_in_progress)) begin
                item.result_data = vif.data_out;
                item.op_error = vif.op_error;
                item.current_len = vif.len;
                item.op_done = vif.op_done;
                ap.write(item);
                item = null;
            end
        end
    endtask

endclass
