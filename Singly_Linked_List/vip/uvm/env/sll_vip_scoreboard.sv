//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_scoreboard
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sll_vip_scoreboard)

    uvm_analysis_imp #(sll_vip_seq_item, sll_vip_scoreboard) analysis_export;
    sll_vip_config cfg;

    // Reference model: queue to track list data and addresses
    int list_data[$];
    int list_addr[$];
    int expected_length;
    int expected_head;
    int expected_tail;

    function new(string name = "sll_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        expected_length = 0;
        expected_head = 0;
        expected_tail = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(sll_vip_config)::get(this, "", "sll_vip_cfg", cfg))
            `uvm_fatal("SCOREBOARD", "No config")
    endfunction

    virtual function void write(sll_vip_seq_item item);
        `uvm_info("SCOREBOARD", $sformatf("Checking: %s", item.convert2string()), UVM_MEDIUM)

        case (item.op)
            INSERT_AT_ADDR: check_insert_at_addr(item);
            INSERT_AT_INDEX: check_insert_at_index(item);
            READ_ADDR: check_read_addr(item);
            DELETE_VALUE: check_delete_value(item);
            DELETE_AT_ADDR: check_delete_at_addr(item);
            DELETE_AT_INDEX: check_delete_at_index(item);
            default: `uvm_info("SCOREBOARD", "IDLE operation, no checking", UVM_HIGH)
        endcase

        // Check list state
        if (item.current_len != expected_length) begin
            `uvm_error("SCOREBOARD", $sformatf("Length mismatch: expected=%0d, actual=%0d",
                      expected_length, item.current_len))
        end
    endfunction

    function void check_insert_at_addr(sll_vip_seq_item item);
        int idx;

        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Insert at addr faulted (expected for invalid addr)", UVM_MEDIUM)
            return;
        end

        // Find position in our model
        idx = -1;
        for (int i = 0; i < list_addr.size(); i++) begin
            if (list_addr[i] == item.addr) begin
                idx = i;
                break;
            end
        end

        if (item.addr == 0 || idx == -1) begin
            // Insert at head (addr 0 or empty list)
            list_data.push_front(item.data);
            list_addr.push_front(item.addr == 0 ? expected_length + 1 : item.addr);
            expected_head = list_addr[0];
        end else begin
            // Insert after specified address
            list_data.insert(idx + 1, item.data);
            list_addr.insert(idx + 1, expected_length + 1);
        end

        if (list_data.size() == 1) expected_tail = list_addr[0];
        else expected_tail = list_addr[$];

        expected_length++;
        `uvm_info("SCOREBOARD", $sformatf("Inserted data=0x%0h at addr=%0d", item.data, item.addr), UVM_HIGH)
    endfunction

    function void check_insert_at_index(sll_vip_seq_item item);
        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Insert at index faulted (expected for invalid index)", UVM_MEDIUM)
            return;
        end

        if (item.addr >= list_data.size()) begin
            list_data.push_back(item.data);
            list_addr.push_back(expected_length + 1);
            expected_tail = list_addr[$];
        end else begin
            list_data.insert(item.addr, item.data);
            list_addr.insert(item.addr, expected_length + 1);
        end

        if (list_data.size() == 1) begin
            expected_head = list_addr[0];
            expected_tail = list_addr[0];
        end

        expected_length++;
        `uvm_info("SCOREBOARD", $sformatf("Inserted data=0x%0h at index=%0d", item.data, item.addr), UVM_HIGH)
    endfunction

    function void check_read_addr(sll_vip_seq_item item);
        int idx;

        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Read faulted (expected for invalid addr)", UVM_MEDIUM)
            return;
        end

        // Find in our model
        idx = -1;
        for (int i = 0; i < list_addr.size(); i++) begin
            if (list_addr[i] == item.addr) begin
                idx = i;
                break;
            end
        end

        if (idx != -1) begin
            if (item.result_data != list_data[idx]) begin
                `uvm_error("SCOREBOARD", $sformatf("Read data mismatch at addr=%0d: expected=0x%0h, actual=0x%0h",
                          item.addr, list_data[idx], item.result_data))
            end
            // Check next pointer
            if (idx < list_addr.size() - 1) begin
                if (item.result_next_addr != list_addr[idx + 1]) begin
                    `uvm_error("SCOREBOARD", $sformatf("Next addr mismatch: expected=%0d, actual=%0d",
                              list_addr[idx + 1], item.result_next_addr))
                end
            end else begin
                if (item.result_next_addr != 0) begin
                    `uvm_error("SCOREBOARD", $sformatf("Expected next_addr=0 for tail, got %0d", item.result_next_addr))
                end
            end
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("Address %0d not found in model", item.addr))
        end
    endfunction

    function void check_delete_value(sll_vip_seq_item item);
        int idx;

        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Delete value faulted (value not found)", UVM_MEDIUM)
            return;
        end

        // Find first occurrence
        idx = -1;
        for (int i = 0; i < list_data.size(); i++) begin
            if (list_data[i] == item.data) begin
                idx = i;
                break;
            end
        end

        if (idx != -1) begin
            list_data.delete(idx);
            list_addr.delete(idx);
            expected_length--;

            if (list_data.size() == 0) begin
                expected_head = 0;
                expected_tail = 0;
            end else begin
                expected_head = list_addr[0];
                expected_tail = list_addr[$];
            end
            `uvm_info("SCOREBOARD", $sformatf("Deleted value=0x%0h", item.data), UVM_HIGH)
        end
    endfunction

    function void check_delete_at_addr(sll_vip_seq_item item);
        int idx;

        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Delete at addr faulted (invalid addr)", UVM_MEDIUM)
            return;
        end

        idx = -1;
        for (int i = 0; i < list_addr.size(); i++) begin
            if (list_addr[i] == item.addr) begin
                idx = i;
                break;
            end
        end

        if (idx != -1) begin
            list_data.delete(idx);
            list_addr.delete(idx);
            expected_length--;

            if (list_data.size() == 0) begin
                expected_head = 0;
                expected_tail = 0;
            end else begin
                expected_head = list_addr[0];
                expected_tail = list_addr[$];
            end
            `uvm_info("SCOREBOARD", $sformatf("Deleted at addr=%0d", item.addr), UVM_HIGH)
        end
    endfunction

    function void check_delete_at_index(sll_vip_seq_item item);
        if (item.fault) begin
            `uvm_info("SCOREBOARD", "Delete at index faulted (invalid index)", UVM_MEDIUM)
            return;
        end

        if (item.addr < list_data.size()) begin
            list_data.delete(item.addr);
            list_addr.delete(item.addr);
            expected_length--;

            if (list_data.size() == 0) begin
                expected_head = 0;
                expected_tail = 0;
            end else begin
                expected_head = list_addr[0];
                expected_tail = list_addr[$];
            end
            `uvm_info("SCOREBOARD", $sformatf("Deleted at index=%0d", item.addr), UVM_HIGH)
        end
    endfunction

endclass
