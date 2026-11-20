//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_driver
//////////////////////////////////////////////////////////////////////////////////

class table_vip_driver extends uvm_driver #(table_vip_seq_item);
    `uvm_component_utils(table_vip_driver)

    virtual table_vip_if vif;
    table_vip_config cfg;

    function new(string name = "table_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual table_vip_if)::get(this, "", "table_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(table_vip_config)::get(this, "", "table_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.wr_en = 0;
        vif.rd_en = 0;
        vif.index_wr = 0;
        vif.index_rd = 0;
        vif.data_wr = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            @(negedge vif.clk);
            vif.wr_en = req.wr_en;
            vif.rd_en = req.rd_en;
            vif.index_wr = {req.index_wr[1], req.index_wr[0]};
            vif.index_rd = {req.index_rd[1], req.index_rd[0]};
            vif.data_wr = {req.data_wr[1], req.data_wr[0]};
            @(posedge vif.clk);
            #1ns;
            req.data_rd[0] = vif.data_rd[7:0];
            req.data_rd[1] = vif.data_rd[15:8];
            @(negedge vif.clk);
            vif.wr_en = 0;
            vif.rd_en = 0;
            seq_item_port.item_done();
        end
    endtask

endclass
