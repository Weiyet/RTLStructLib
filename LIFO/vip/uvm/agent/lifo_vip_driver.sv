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
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(lifo_vip_seq_item item);
        case (item.op)
            PUSH: drive_push(item);
            POP: drive_pop(item);
            IDLE: drive_idle();
        endcase
    endtask

    task drive_push(lifo_vip_seq_item item);
        @(vif.cb);
        vif.cb.wr_en <= 1'b1;
        vif.cb.rd_en <= 1'b0;
        vif.cb.data_wr <= item.data[cfg.DATA_WIDTH-1:0];

        @(vif.cb);
        item.full = vif.cb.lifo_full;
        item.success = !vif.cb.lifo_full;

        vif.cb.wr_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("Push: data=0x%0h full=%0b", item.data, item.full), UVM_HIGH)
    endtask

    task drive_pop(lifo_vip_seq_item item);
        @(vif.cb);
        vif.cb.rd_en <= 1'b1;
        vif.cb.wr_en <= 1'b0;

        @(vif.cb);
        item.empty = vif.cb.lifo_empty;
        item.read_data = vif.cb.data_rd;
        item.success = !vif.cb.lifo_empty;

        vif.cb.rd_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("Pop: data=0x%0h empty=%0b", item.read_data, item.empty), UVM_HIGH)
    endtask

    task drive_idle();
        @(vif.cb);
        vif.cb.wr_en <= 1'b0;
        vif.cb.rd_en <= 1'b0;
    endtask

endclass
