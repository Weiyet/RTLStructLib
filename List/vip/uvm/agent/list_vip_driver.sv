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
        // Initialize signals
        vif.cb.op_sel <= 3'b000;
        vif.cb.op_en <= 1'b0;
        vif.cb.data_in <= '0;
        vif.cb.index_in <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(list_vip_seq_item item);
        case (item.op)
            READ: drive_read(item);
            INSERT: drive_insert(item);
            DELETE: drive_delete(item);
            FIND_1ST: drive_find_1st(item);
            FIND_ALL: drive_find_all(item);
            SUM: drive_sum(item);
            SORT_ASC: drive_sort_asc(item);
            SORT_DES: drive_sort_des(item);
            IDLE: drive_idle();
        endcase
    endtask

    task drive_read(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b000;
        vif.cb.op_en <= 1'b1;
        vif.cb.index_in <= item.index;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.result_data = vif.cb.data_out;
        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;
        item.current_len = vif.cb.len;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("READ[%0d]: data=0x%0h error=%0b", item.index, item.result_data, item.op_error), UVM_HIGH)
    endtask

    task drive_insert(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b001;
        vif.cb.op_en <= 1'b1;
        vif.cb.index_in <= item.index;
        vif.cb.data_in <= item.data;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;
        item.current_len = vif.cb.len;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("INSERT[%0d]: data=0x%0h error=%0b len=%0d", item.index, item.data, item.op_error, item.current_len), UVM_HIGH)
    endtask

    task drive_delete(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b111;
        vif.cb.op_en <= 1'b1;
        vif.cb.index_in <= item.index;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;
        item.current_len = vif.cb.len;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("DELETE[%0d]: error=%0b len=%0d", item.index, item.op_error, item.current_len), UVM_HIGH)
    endtask

    task drive_find_1st(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b011;
        vif.cb.op_en <= 1'b1;
        vif.cb.data_in <= item.data;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.result_data = vif.cb.data_out;
        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("FIND_1ST(0x%0h): index=%0d error=%0b", item.data, item.result_data, item.op_error), UVM_HIGH)
    endtask

    task drive_find_all(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b010;
        vif.cb.op_en <= 1'b1;
        vif.cb.data_in <= item.data;

        // FIND_ALL can take multiple cycles and return multiple indices
        @(vif.cb);
        while (vif.cb.op_in_progress || !vif.cb.op_done) begin
            @(vif.cb);
        end

        item.result_data = vif.cb.data_out;
        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;

        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("FIND_ALL(0x%0h): completed error=%0b", item.data, item.op_error), UVM_HIGH)
    endtask

    task drive_sum(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b100;
        vif.cb.op_en <= 1'b1;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.result_data = vif.cb.data_out;
        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", $sformatf("SUM: result=%0d error=%0b", item.result_data, item.op_error), UVM_HIGH)
    endtask

    task drive_sort_asc(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b101;
        vif.cb.op_en <= 1'b1;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", "SORT_ASC: completed", UVM_HIGH)
    endtask

    task drive_sort_des(list_vip_seq_item item);
        @(vif.cb);
        vif.cb.op_sel <= 3'b110;
        vif.cb.op_en <= 1'b1;

        @(vif.cb);
        wait(vif.cb.op_done);

        item.op_done = vif.cb.op_done;
        item.op_error = vif.cb.op_error;

        @(vif.cb);
        vif.cb.op_en <= 1'b0;

        `uvm_info("DRIVER", "SORT_DES: completed", UVM_HIGH)
    endtask

    task drive_idle();
        @(vif.cb);
        vif.cb.op_en <= 1'b0;
    endtask

endclass
