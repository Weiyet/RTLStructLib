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
        vif.cb.op_sel <= 2'b11;
        vif.cb.op_en <= 1'b0;
        vif.cb.key_in <= '0;
        vif.cb.value_in <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(ht_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= item.op;
        vif.cb.op_en <= 1'b1;
        vif.cb.key_in <= item.key;
        vif.cb.value_in <= item.value;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        wait(vif.cb.op_done);

        item.result_value = vif.cb.value_out;
        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;
        item.collision_count = vif.cb.collision_count;

        @(vif.cb);

        `uvm_info("DRIVER", $sformatf("%s: key=0x%0h value=0x%0h error=%0b",
                  item.op.name(), item.key, item.value, item.op_error), UVM_HIGH)
    endtask

endclass
