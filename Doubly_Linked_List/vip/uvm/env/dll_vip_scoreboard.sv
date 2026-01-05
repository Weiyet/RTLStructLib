//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_scoreboard
// Description: Scoreboard for Doubly Linked List VIP with linked list model
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dll_vip_scoreboard)

    uvm_analysis_imp #(dll_vip_seq_item, dll_vip_scoreboard) imp;

    dll_vip_config cfg;
    int list_data[$];
    int list_addr[$];
    int error_count;
    int insert_count, delete_count, read_count;

    function new(string name = "dll_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(dll_vip_config)::get(this, "", "dll_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")
    endfunction

    function void write(dll_vip_seq_item item);
        case (item.op)
            READ_ADDR: check_read(item);
            INSERT_AT_ADDR, INSERT_AT_INDEX: check_insert(item);
            DELETE_VALUE, DELETE_AT_ADDR, DELETE_AT_INDEX: check_delete(item);
        endcase

        if (item.current_len != list_data.size()) begin
            `uvm_error("SCOREBOARD", $sformatf("Length mismatch! Expected=%0d Actual=%0d",
                       list_data.size(), item.current_len))
            error_count++;
        end
    endfunction

    function void check_read(dll_vip_seq_item item);
        int index;
        read_count++;

        index = find_addr_index(item.addr);
        if (index == -1) begin
            if (!item.fault)
                error_count++;
        end else begin
            if (item.result_data != list_data[index]) begin
                `uvm_error("SCOREBOARD", $sformatf("READ mismatch! Expected=0x%0h Actual=0x%0h",
                           list_data[index], item.result_data))
                error_count++;
            end
        end
    endfunction

    function void check_insert(dll_vip_seq_item item);
        int next_addr;
        insert_count++;

        if (list_data.size() >= cfg.MAX_NODE) begin
            if (!item.fault) error_count++;
        end else if (!item.fault) begin
            next_addr = find_next_free_addr();
            if (item.op == INSERT_AT_INDEX) begin
                if (item.addr >= list_data.size()) begin
                    list_data.push_back(item.data);
                    list_addr.push_back(next_addr);
                end else begin
                    list_data.insert(item.addr, item.data);
                    list_addr.insert(item.addr, next_addr);
                end
            end else begin
                list_data.push_back(item.data);
                list_addr.push_back(next_addr);
            end
            `uvm_info("SCOREBOARD", $sformatf("INSERT: data=0x%0h addr=%0d len=%0d",
                      item.data, next_addr, list_data.size()), UVM_MEDIUM)
        end
    endfunction

    function void check_delete(dll_vip_seq_item item);
        int index;
        delete_count++;

        if (item.op == DELETE_VALUE) begin
            index = list_data.find_first_index(x) with (x == item.data);
            if (index.size() > 0 && !item.fault) begin
                list_data.delete(index[0]);
                list_addr.delete(index[0]);
            end
        end else begin
            index = item.op == DELETE_AT_INDEX ? item.addr : find_addr_index(item.addr);
            if (index != -1 && index < list_data.size() && !item.fault) begin
                list_data.delete(index);
                list_addr.delete(index);
            end
        end
        `uvm_info("SCOREBOARD", $sformatf("DELETE: len=%0d", list_data.size()), UVM_MEDIUM)
    endfunction

    function int find_addr_index(int addr);
        for (int i = 0; i < list_addr.size(); i++) begin
            if (list_addr[i] == addr) return i;
        end
        return -1;
    endfunction

    function int find_next_free_addr();
        for (int i = 0; i < cfg.MAX_NODE; i++) begin
            if (find_addr_index(i) == -1) return i;
        end
        return -1;
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Insert Count: %0d", insert_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Delete Count: %0d", delete_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Read Count: %0d", read_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Error Count: %0d", error_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Final List Size: %0d", list_data.size()), UVM_LOW)
        `uvm_info("SCOREBOARD", "==============================================", UVM_LOW)

        if (error_count > 0)
            `uvm_error("SCOREBOARD", $sformatf("Test FAILED with %0d errors", error_count))
        else
            `uvm_info("SCOREBOARD", "Test PASSED - No errors detected", UVM_LOW)
    endfunction

endclass
