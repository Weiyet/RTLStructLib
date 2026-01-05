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
            @(vif.mon_cb);

            // Detect push operation
            if (vif.mon_cb.wr_en && !vif.mon_cb.rd_en) begin
                item = lifo_vip_seq_item::type_id::create("item");
                item.op = PUSH;
                item.data = vif.mon_cb.data_wr;
                item.full = vif.mon_cb.lifo_full;
                item.success = !vif.mon_cb.lifo_full;
                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed PUSH: data=0x%0h full=%0b", item.data, item.full), UVM_HIGH)
            end

            // Detect pop operation
            else if (vif.mon_cb.rd_en && !vif.mon_cb.wr_en) begin
                @(vif.mon_cb); // Wait one cycle to capture read data
                item = lifo_vip_seq_item::type_id::create("item");
                item.op = POP;
                item.read_data = vif.mon_cb.data_rd;
                item.empty = vif.mon_cb.lifo_empty;
                item.success = !vif.mon_cb.lifo_empty;
                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed POP: data=0x%0h empty=%0b", item.read_data, item.empty), UVM_HIGH)
            end

            // Detect simultaneous push/pop (bypass)
            else if (vif.mon_cb.wr_en && vif.mon_cb.rd_en) begin
                @(vif.mon_cb);
                item = lifo_vip_seq_item::type_id::create("item");
                item.op = PUSH; // Record as push for scoreboard
                item.data = vif.mon_cb.data_wr;
                item.read_data = vif.mon_cb.data_rd; // Bypass data
                item.full = vif.mon_cb.lifo_full;
                item.empty = vif.mon_cb.lifo_empty;
                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed BYPASS: wr=0x%0h rd=0x%0h", item.data, item.read_data), UVM_HIGH)
            end
        end
    endtask

endclass
