//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_driver
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_driver extends uvm_driver #(deff_vip_seq_item);
    `uvm_component_utils(deff_vip_driver)

    virtual deff_vip_if vif;
    deff_vip_config cfg;

    function new(string name = "deff_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual deff_vip_if)::get(this, "", "deff_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(deff_vip_config)::get(this, "", "deff_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.cb.data_in <= '0;
        vif.cb.pos_edge_latch_en <= '0;
        vif.cb.neg_edge_latch_en <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(deff_vip_seq_item item);
        @(vif.cb);
        vif.cb.data_in <= item.data_in;
        vif.cb.pos_edge_latch_en <= item.pos_edge_latch_en;
        vif.cb.neg_edge_latch_en <= item.neg_edge_latch_en;

        // Wait for data to propagate through dual-edge FF
        @(vif.cb);
        item.data_out = vif.cb.data_out;

        `uvm_info("DRIVER", $sformatf("Drove: data_in=0x%0h pos_en=0x%0h neg_en=0x%0h -> data_out=0x%0h",
                  item.data_in, item.pos_edge_latch_en, item.neg_edge_latch_en, item.data_out), UVM_HIGH)
    endtask

endclass
