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
        vif.op_start = 0;
        vif.op = 0;
        vif.data_in = 0;
        vif.addr_in = 0;
        wait (!vif.rst);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(sll_vip_seq_item item);
        if (item.op == IDLE) begin
            @(negedge vif.clk);
            return;
        end
        @(negedge vif.clk);
        wait (!vif.rst);
        vif.op = item.op;
        vif.data_in = item.data;
        vif.addr_in = item.addr;
        vif.op_start = 1;
        @(posedge vif.clk);
        #1ns;
        @(negedge vif.clk);
        vif.op_start = 0;
        while (!(vif.op_done) && !vif.rst) begin
            @(posedge vif.clk);
            #1ns;
        end
                item.result_data = vif.data_out;
                item.result_next_addr = vif.next_node_addr;
                item.fault = vif.fault;
                item.current_len = vif.length;
                item.current_head = vif.head;
                item.current_tail = vif.tail;
                item.full = vif.full;
                item.empty = vif.empty;
        item.op_done = vif.op_done;
        // Leave one cleanup clock after completion before a new request.
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

endclass
