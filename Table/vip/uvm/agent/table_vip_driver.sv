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
        vif.cb.wr_en <= 2'b00;
        vif.cb.rd_en <= 1'b0;
        vif.cb.index_wr <= '0;
        vif.cb.index_rd <= '0;
        vif.cb.data_wr <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(table_vip_seq_item item);
        if (item.op == WRITE) begin
            drive_write(item);
        end else begin
            drive_read(item);
        end
    endtask

    task drive_write(table_vip_seq_item item);
        @(vif.cb);
        vif.cb.wr_en <= item.wr_en;
        vif.cb.rd_en <= 1'b0;

        // Pack write indices
        vif.cb.index_wr[4:0] <= item.index_wr[0];
        vif.cb.index_wr[9:5] <= item.index_wr[1];

        // Pack write data
        vif.cb.data_wr[7:0] <= item.data_wr[0];
        vif.cb.data_wr[15:8] <= item.data_wr[1];

        @(vif.cb);
        vif.cb.wr_en <= 2'b00;

        `uvm_info("DRIVER", $sformatf("WRITE: wr_en=0x%0h idx[0]=%0d data[0]=0x%0h idx[1]=%0d data[1]=0x%0h",
                  item.wr_en, item.index_wr[0], item.data_wr[0], item.index_wr[1], item.data_wr[1]), UVM_HIGH)
    endtask

    task drive_read(table_vip_seq_item item);
        @(vif.cb);
        vif.cb.rd_en <= 1'b1;
        vif.cb.wr_en <= 2'b00;

        // Pack read indices
        vif.cb.index_rd[4:0] <= item.index_rd[0];
        vif.cb.index_rd[9:5] <= item.index_rd[1];

        @(vif.cb);

        // Unpack read data
        item.data_rd[0] = vif.cb.data_rd[7:0];
        item.data_rd[1] = vif.cb.data_rd[15:8];

        vif.cb.rd_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("READ: idx[0]=%0d data[0]=0x%0h idx[1]=%0d data[1]=0x%0h",
                  item.index_rd[0], item.data_rd[0], item.index_rd[1], item.data_rd[1]), UVM_HIGH)
    endtask

endclass
