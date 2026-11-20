//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 08:45 PM
// Module Name: fifo_vip_driver
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP driver.
//
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_driver extends uvm_driver #(fifo_vip_seq_item);
    `uvm_component_utils(fifo_vip_driver)

    virtual fifo_vip_if vif;
    fifo_vip_config cfg;
    string driver_type; // "WR" or "RD"

    function new(string name = "fifo_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual fifo_vip_if)::get(this, "", "fifo_vip_vif", vif))
            `uvm_fatal("DRV", "No virtual interface")
        if (!uvm_config_db#(fifo_vip_config)::get(this, "", "fifo_vip_cfg", cfg))
            `uvm_fatal("DRV", "No config")

        if (!uvm_config_db#(string)::get(this, "", "fifo_role", driver_type))
            `uvm_fatal("DRIVER", "No FIFO agent role")
    endfunction

    task run_phase(uvm_phase phase);
        if (driver_type == "WR") begin
            vif.wr_en = 0;
            vif.data_wr = 0;
        end else vif.rd_en = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            req.cfg = cfg;
            if (driver_type == "WR") begin
                @(negedge vif.wr_clk);
                vif.data_wr = req.data;
                vif.wr_en = (req.op == WRITE);
                @(posedge vif.wr_clk);
                req.success = !vif.rst && !vif.fifo_full;
                @(negedge vif.wr_clk);
                vif.wr_en = 0;
            end else begin
                @(negedge vif.rd_clk);
                vif.rd_en = (req.op == READ);
                @(posedge vif.rd_clk);
                req.success = !vif.rst && !vif.fifo_empty;
                if (cfg.RD_BUFFER) #1ns;
                req.read_data = vif.data_rd;
                @(negedge vif.rd_clk);
                vif.rd_en = 0;
            end
            seq_item_port.item_done();
        end
    endtask
endclass
