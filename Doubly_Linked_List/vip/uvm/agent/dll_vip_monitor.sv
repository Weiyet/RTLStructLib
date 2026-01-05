//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_monitor
// Description: Monitor for Doubly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_monitor extends uvm_monitor;
    `uvm_component_utils(dll_vip_monitor)

    virtual dll_vip_if vif;
    dll_vip_config cfg;
    uvm_analysis_port #(dll_vip_seq_item) ap;

    function new(string name = "dll_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dll_vip_if)::get(this, "", "dll_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(dll_vip_config)::get(this, "", "dll_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        dll_vip_seq_item item;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.op_start) begin
                item = dll_vip_seq_item::type_id::create("item");

                case (vif.mon_cb.op)
                    3'b000: item.op = READ_ADDR;
                    3'b001: item.op = INSERT_AT_ADDR;
                    3'b010: item.op = DELETE_VALUE;
                    3'b011: item.op = DELETE_AT_ADDR;
                    3'b101: item.op = INSERT_AT_INDEX;
                    3'b111: item.op = DELETE_AT_INDEX;
                    default: item.op = IDLE;
                endcase

                item.data = vif.mon_cb.data_in;
                item.addr = vif.mon_cb.addr_in;

                @(vif.mon_cb);
                while (!vif.mon_cb.op_done) @(vif.mon_cb);

                item.result_data = vif.mon_cb.data_out;
                item.result_pre_addr = vif.mon_cb.pre_node_addr;
                item.result_next_addr = vif.mon_cb.next_node_addr;
                item.op_done = vif.mon_cb.op_done;
                item.fault = vif.mon_cb.fault;
                item.current_len = vif.mon_cb.length;
                item.current_head = vif.mon_cb.head;
                item.current_tail = vif.mon_cb.tail;

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s", item.convert2string()), UVM_HIGH)
            end
        end
    endtask

endclass
