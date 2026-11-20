//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_monitor
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_monitor extends uvm_monitor;
    `uvm_component_utils(ht_vip_monitor)

    virtual ht_vip_if vif;
    ht_vip_config cfg;
    uvm_analysis_port #(ht_vip_seq_item) ap;

    function new(string name = "ht_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ht_vip_if)::get(this, "", "ht_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(ht_vip_config)::get(this, "", "ht_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        ht_vip_seq_item item;
        forever begin
            @(posedge vif.clk);
            if (vif.rst) begin
                item = ht_vip_seq_item::type_id::create("reset");
                item.reset_seen = 1;
                ap.write(item);
                item = null;
                continue;
            end
            // Capture pins at acceptance, before nonblocking RTL updates.
            if (item == null && vif.op_en && !vif.op_done) begin
                item = ht_vip_seq_item::type_id::create("request");
                item.op = ht_op_e'(vif.op_sel);
                item.key = vif.key_in;
                item.value = vif.value_in;
            end
            #1ns;
            if (item != null && (vif.op_done)) begin
                item.result_value = vif.value_out;
                item.op_error = vif.op_error;
                item.collision_count = vif.collision_count;
                item.op_done = vif.op_done;
                ap.write(item);
                item = null;
            end
        end
    endtask

endclass
