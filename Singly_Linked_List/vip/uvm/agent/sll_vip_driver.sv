//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_driver
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_driver extends uvm_driver #(sll_vip_seq_item);
    `uvm_component_utils(sll_vip_driver)

    virtual sll_vip_if vif;
    sll_vip_config cfg;

    function new(string name = "sll_vip_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sll_vip_if)::get(this, "", "sll_vip_vif", vif))
            `uvm_fatal("DRIVER", "No virtual interface")
        if (!uvm_config_db#(sll_vip_config)::get(this, "", "sll_vip_cfg", cfg))
            `uvm_fatal("DRIVER", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        vif.cb.op <= 3'b000;
        vif.cb.op_start <= 1'b0;
        vif.cb.data_in <= '0;
        vif.cb.addr_in <= '0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(sll_vip_seq_item item);
        @(vif.cb);
        vif.cb.op <= item.op;
        vif.cb.op_start <= 1'b1;
        vif.cb.data_in <= item.data[cfg.DATA_WIDTH-1:0];
        vif.cb.addr_in <= item.addr[$clog2(cfg.MAX_NODE+1)-1:0];

        @(vif.cb);
        wait(vif.cb.op_done);

        item.result_data = vif.cb.data_out;
        item.result_next_addr = vif.cb.next_node_addr;
        item.op_done = vif.cb.op_done;
        item.fault = vif.cb.fault;
        item.current_len = vif.cb.length;
        item.current_head = vif.cb.head;
        item.current_tail = vif.cb.tail;

        @(vif.cb);
        vif.cb.op_start <= 1'b0;

        `uvm_info("DRIVER", $sformatf("%s: addr=%0d data=0x%0h fault=%0b",
                  item.op.name(), item.addr, item.data, item.fault), UVM_HIGH)
    endtask

endclass
