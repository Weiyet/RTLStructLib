//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_driver
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_driver extends uvm_driver #(ht_vip_seq_item);
    `uvm_component_utils(ht_vip_driver)

    virtual ht_vip_if vif;
    ht_vip_config cfg;

    function new(string name = "ht_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ht_vip_if)::get(this, "", "ht_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(ht_vip_config)::get(this, "", "ht_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.op_en = 0;
        vif.op_sel = 0;
        vif.key_in = 0;
        vif.value_in = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(ht_vip_seq_item item);
        @(negedge vif.clk);
        wait (!vif.rst);
        vif.op_sel = item.op;
        vif.key_in = item.key;
        vif.value_in = item.value;
        vif.op_en = 1;
        @(posedge vif.clk);
        #1ns;
        @(negedge vif.clk);
        vif.op_en = 0;
        while (!(vif.op_done) && !vif.rst) begin
            @(posedge vif.clk);
            #1ns;
        end
                item.result_value = vif.value_out;
                item.op_error = vif.op_error;
                item.collision_count = vif.collision_count;
        item.op_done = vif.op_done;
        // Leave one cleanup clock after completion before a new request.
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

endclass
