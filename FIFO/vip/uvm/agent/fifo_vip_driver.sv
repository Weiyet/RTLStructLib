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
        if (!uvm_config_db#(virtual fifo_vip_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "No virtual interface")
        if (!uvm_config_db#(fifo_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("DRV", "No config")
            
        // Figure out if this is write or read driver
        driver_type = (get_name().substr(0,1) == "w") ? "WR" : "RD";
    endfunction
    
    task run_phase(uvm_phase phase);
        fifo_vip_seq_item item;
        
        // Initialize
        if (driver_type == "WR") begin
            vif.wr_cb.wr_en <= 0;
            vif.wr_cb.data_wr <= 0;
        end else begin
            vif.rd_cb.rd_en <= 0;
        end
        
        // Wait for reset
        @(negedge vif.rst);
        @(posedge vif.wr_clk);
        
        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask
    
    task drive_item(fifo_vip_seq_item item);
        // Set config on item
        item.set_config(cfg);
        
        case (item.op)
            WRITE: if (driver_type == "WR") drive_write(item);
            READ:  if (driver_type == "RD") drive_read(item);
            IDLE:  repeat(2) @(vif.wr_cb);
        endcase
    endtask
    
    task drive_write(fifo_vip_seq_item item);
        @(vif.wr_cb);
        vif.wr_cb.data_wr <= item.data[cfg.DATA_WIDTH-1:0];
        vif.wr_cb.wr_en <= 1;
        @(vif.wr_cb);
        item.full = vif.wr_cb.fifo_full;
        item.success = !vif.wr_cb.fifo_full;
        vif.wr_cb.wr_en <= 0;
        `uvm_info("WR_DRV", $sformatf("Write: %s", item.convert2string()), UVM_HIGH)
    endtask
    
    task drive_read(fifo_vip_seq_item item);
        @(vif.rd_cb);
        vif.rd_cb.rd_en <= 1;
        @(vif.rd_cb);
        item.empty = vif.rd_cb.fifo_empty;
        item.success = !vif.rd_cb.fifo_empty;
        if (cfg.RD_BUFFER) @(vif.rd_cb); // Wait extra cycle for buffered read
        item.read_data = vif.rd_cb.data_rd;
        vif.rd_cb.rd_en <= 0;
        `uvm_info("RD_DRV", $sformatf("Read: %s", item.convert2string()), UVM_HIGH)
    endtask

endclass