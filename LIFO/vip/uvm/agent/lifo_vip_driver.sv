//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_driver
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Driver for LIFO VIP - drives transactions to DUT
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_driver extends uvm_driver #(lifo_vip_seq_item);
    `uvm_component_utils(lifo_vip_driver)

    virtual lifo_vip_if vif;
    lifo_vip_config cfg;

    function new(string name = "lifo_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual lifo_vip_if)::get(this, "", "lifo_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(lifo_vip_config)::get(this, "", "lifo_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.wr_en = 0;
        vif.rd_en = 0;
        vif.data_wr = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            @(negedge vif.clk);
            vif.data_wr = req.data;
            vif.wr_en = req.op == PUSH || req.bypass;
            vif.rd_en = req.op == POP || req.bypass;
            @(posedge vif.clk);
            req.success = req.bypass || (req.op == PUSH ? !vif.lifo_full : !vif.lifo_empty);
            #1ns;
            req.read_data = vif.data_rd;
            @(negedge vif.clk);
            vif.wr_en = 0;
            vif.rd_en = 0;
            seq_item_port.item_done();
        end
    endtask

endclass
