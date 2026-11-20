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
        vif.data_in = 0;
        vif.pos_edge_latch_en = 0;
        vif.neg_edge_latch_en = 0;
        wait (vif.rst_n);
        forever begin
            seq_item_port.get_next_item(req);
            @(negedge vif.clk);
            #2ns;
            vif.data_in = req.data_in;
            vif.pos_edge_latch_en = req.pos_edge_latch_en;
            vif.neg_edge_latch_en = req.neg_edge_latch_en;
            @(posedge vif.clk);
            @(negedge vif.clk);
            #2ns;
            req.data_out = vif.data_out;
            vif.pos_edge_latch_en = 0;
            vif.neg_edge_latch_en = 0;
            seq_item_port.item_done();
        end
    endtask

endclass
