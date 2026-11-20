//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_monitor
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_monitor extends uvm_monitor;
    `uvm_component_utils(sll_vip_monitor)

    virtual sll_vip_if vif;
    sll_vip_config cfg;
    uvm_analysis_port #(sll_vip_seq_item) ap;

    function new(string name = "sll_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sll_vip_if)::get(this, "", "sll_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(sll_vip_config)::get(this, "", "sll_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        sll_vip_seq_item item;
        forever begin
            @(posedge vif.clk);
            if (vif.rst) begin
                item = sll_vip_seq_item::type_id::create("reset");
                item.reset_seen = 1;
                ap.write(item);
                item = null;
                continue;
            end
            // Capture pins at acceptance, before nonblocking RTL updates.
            if (item == null && vif.op_start && !vif.op_done) begin
                item = sll_vip_seq_item::type_id::create("request");
                item.op = sll_op_e'(vif.op);
                item.data = vif.data_in;
                item.addr = vif.addr_in;
            end
            #1ns;
            if (item != null && (vif.op_done)) begin
                item.result_data = vif.data_out;
                item.result_next_addr = vif.next_node_addr;
                item.fault = vif.fault;
                item.current_len = vif.length;
                item.current_head = vif.head;
                item.current_tail = vif.tail;
                item.full = vif.full;
                item.empty = vif.empty;
                item.op_done = vif.op_done;
                ap.write(item);
                item = null;
            end
        end
    endtask

endclass
