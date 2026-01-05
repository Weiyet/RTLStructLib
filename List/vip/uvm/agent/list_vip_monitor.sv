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
            @(vif.mon_cb);

            // Detect operation when op_en is asserted
            if (vif.mon_cb.op_en) begin
                item = list_vip_seq_item::type_id::create("item");

                // Capture operation type
                case (vif.mon_cb.op_sel)
                    3'b000: item.op = READ;
                    3'b001: item.op = INSERT;
                    3'b010: item.op = FIND_ALL;
                    3'b011: item.op = FIND_1ST;
                    3'b100: item.op = SUM;
                    3'b101: item.op = SORT_ASC;
                    3'b110: item.op = SORT_DES;
                    3'b111: item.op = DELETE;
                endcase

                // Capture inputs
                item.data = vif.mon_cb.data_in;
                item.index = vif.mon_cb.index_in;

                // Wait for operation to complete
                @(vif.mon_cb);
                while (!vif.mon_cb.op_done) begin
                    @(vif.mon_cb);
                end

                // Capture outputs
                item.result_data = vif.mon_cb.data_out;
                item.op_done = vif.mon_cb.op_done;
                item.op_error = vif.mon_cb.op_error;
                item.current_len = vif.mon_cb.len;

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s: %s", item.op.name(), item.convert2string()), UVM_HIGH)
            end
        end
    endtask

endclass
