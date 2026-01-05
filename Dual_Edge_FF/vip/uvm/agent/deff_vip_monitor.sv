//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_monitor
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_monitor extends uvm_monitor;
    `uvm_component_utils(deff_vip_monitor)

    virtual deff_vip_if vif;
    deff_vip_config cfg;
    uvm_analysis_port #(deff_vip_seq_item) ap;

    function new(string name = "deff_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual deff_vip_if)::get(this, "", "deff_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(deff_vip_config)::get(this, "", "deff_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_seq_item item;

        forever begin
            @(vif.mon_cb);

            // Check if any latch enable is active
            if ((vif.mon_cb.pos_edge_latch_en | vif.mon_cb.neg_edge_latch_en) != 8'h00) begin
                item = deff_vip_seq_item::type_id::create("item");

                item.data_in = vif.mon_cb.data_in;
                item.pos_edge_latch_en = vif.mon_cb.pos_edge_latch_en;
                item.neg_edge_latch_en = vif.mon_cb.neg_edge_latch_en;

                // Wait for next clock edge to capture output
                @(vif.mon_cb);
                item.data_out = vif.mon_cb.data_out;

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s", item.convert2string()), UVM_HIGH)
            end
        end
    endtask

endclass
