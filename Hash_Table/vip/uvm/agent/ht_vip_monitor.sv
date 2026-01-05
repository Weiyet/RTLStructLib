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
            @(vif.mon_cb);

            if (vif.mon_cb.op_en) begin
                item = ht_vip_seq_item::type_id::create("item");

                case (vif.mon_cb.op_sel)
                    2'b00: item.op = INSERT;
                    2'b01: item.op = DELETE;
                    2'b10: item.op = SEARCH;
                    default: item.op = IDLE;
                endcase

                item.key = vif.mon_cb.key_in;
                item.value = vif.mon_cb.value_in;

                @(vif.mon_cb);
                while (!vif.mon_cb.op_done) @(vif.mon_cb);

                item.result_value = vif.mon_cb.value_out;
                item.op_done = vif.mon_cb.op_done;
                item.op_error = vif.mon_cb.op_error;
                item.collision_count = vif.mon_cb.collision_count;

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s", item.convert2string()), UVM_HIGH)
            end
        end
    endtask

endclass
