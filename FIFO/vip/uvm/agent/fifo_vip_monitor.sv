//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 08:56 PM
// Module Name: fifo_vip_monitor
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP monitor.
//
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_vip_monitor)

    virtual fifo_vip_if vif;
    fifo_vip_config cfg;
    uvm_analysis_port #(fifo_vip_seq_item) ap;
    string monitor_type; // "WR" or "RD"

    function new(string name = "fifo_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual fifo_vip_if)::get(this, "", "fifo_vip_vif", vif))
            `uvm_fatal("MON", "No virtual interface")
        if (!uvm_config_db#(fifo_vip_config)::get(this, "", "fifo_vip_cfg", cfg))
            `uvm_fatal("MON", "No config")

        if (!uvm_config_db#(string)::get(this, "", "fifo_role", monitor_type))
            `uvm_fatal("MONITOR", "No FIFO agent role")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_vip_seq_item item;
        forever begin
            if (monitor_type == "WR") begin
                @(posedge vif.wr_clk);
                if (vif.rst) begin
                    item = fifo_vip_seq_item::type_id::create("reset");
                    item.reset_seen = 1;
                    ap.write(item);
                end else if (vif.wr_en) begin
                    item = fifo_vip_seq_item::type_id::create("write");
                    item.op = WRITE;
                    item.data = vif.data_wr;
                    item.full = vif.fifo_full;
                    item.success = !vif.fifo_full;
                    ap.write(item);
                end
            end else begin
                @(posedge vif.rd_clk);
                if (!vif.rst && vif.rd_en) begin
                    item = fifo_vip_seq_item::type_id::create("read");
                    item.op = READ;
                    item.empty = vif.fifo_empty;
                    item.success = !vif.fifo_empty;
                    if (cfg.RD_BUFFER) #1ns;
                    item.read_data = vif.data_rd;
                    ap.write(item);
                end
            end
        end
    endtask
endclass
