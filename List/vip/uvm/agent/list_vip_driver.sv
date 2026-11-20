//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_driver
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Driver for List VIP - drives transactions to DUT
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_driver extends uvm_driver #(list_vip_seq_item);
    `uvm_component_utils(list_vip_driver)

    virtual list_vip_if vif;
    list_vip_config cfg;

    function new(string name = "list_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual list_vip_if)::get(this, "", "list_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(list_vip_config)::get(this, "", "list_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.op_en = 0;
        vif.op_sel = 0;
        vif.data_in = 0;
        vif.index_in = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(list_vip_seq_item item);
        if (item.op == IDLE) begin
            @(negedge vif.clk);
            return;
        end
        @(negedge vif.clk);
        wait (!vif.rst);
        vif.op_sel = item.op;
        vif.data_in = item.data;
        vif.index_in = item.index;
        vif.op_en = 1;
        @(posedge vif.clk);
        #1ns;
        @(negedge vif.clk);
        vif.op_en = 0;
        while (!(vif.op_done && !vif.op_in_progress) && !vif.rst) begin
            @(posedge vif.clk);
            #1ns;
        end
                item.result_data = vif.data_out;
                item.op_error = vif.op_error;
                item.current_len = vif.len;
        item.op_done = vif.op_done;
        // Leave one cleanup clock after completion before a new request.
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

endclass
