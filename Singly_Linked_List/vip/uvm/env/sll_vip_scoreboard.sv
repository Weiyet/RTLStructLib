// Independent ordered-node model with deterministic lowest-free-address allocation.
class sll_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sll_vip_scoreboard)
    uvm_analysis_imp #(sll_vip_seq_item, sll_vip_scoreboard) analysis_export;
    sll_vip_config cfg;
    int data_model[$], address_model[$];
    int last_data, last_next, last_prev;
    int checked_transactions;

    function new(string name = "sll_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(sll_vip_config)::get(this, "", "sll_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing linked-list configuration")
        reset_model();
    endfunction

    function void reset_model();
        data_model.delete();
        address_model.delete();
        last_data = 0;
        last_next = cfg.MAX_NODE;
        last_prev = cfg.MAX_NODE;
    endfunction

    function int address_index(int address);
        foreach (address_model[i]) if (address_model[i] == address) return i;
        return -1;
    endfunction

    function int free_address();
        for (int address = 0; address < cfg.MAX_NODE; address++)
            if (address_index(address) == -1) return address;
        return cfg.MAX_NODE;
    endfunction

    function void write(sll_vip_seq_item item);
        int index, position, address, expected_head, expected_tail;
        bit expected_fault;
        if (item.reset_seen) begin
            reset_model();
            return;
        end
        checked_transactions++;
        index = address_index(item.addr);
        expected_fault = 0;
        case (item.op)
            READ_ADDR: begin
                expected_fault = index < 0;
                if (!expected_fault) begin
                    last_data = data_model[index];
                    last_next = index+1 < address_model.size() ? address_model[index+1] : cfg.MAX_NODE;
                    last_prev = index > 0 ? address_model[index-1] : cfg.MAX_NODE;
                end
            end
            INSERT_AT_ADDR, INSERT_AT_INDEX: begin
                position = item.op == INSERT_AT_INDEX ? int'(item.addr) :
                           (item.addr >= cfg.MAX_NODE ? data_model.size() : index);
                expected_fault = data_model.size() == cfg.MAX_NODE || position < 0;
                if (!expected_fault) begin
                    address = free_address();
                    if (position >= data_model.size()) begin
                        data_model.push_back(item.data);
                        address_model.push_back(address);
                    end else begin
                        data_model.insert(position, item.data);
                        address_model.insert(position, address);
                    end
                end
            end
            DELETE_VALUE, DELETE_AT_ADDR, DELETE_AT_INDEX: begin
                position = item.op == DELETE_AT_INDEX ? int'(item.addr) : index;
                if (item.op == DELETE_VALUE) begin
                    position = -1;
                    foreach (data_model[i]) if (data_model[i] == item.data) begin
                        position = i;
                        break;
                    end
                end
                expected_fault = position < 0 || position >= data_model.size();
                if (!expected_fault) begin
                    data_model.delete(position);
                    address_model.delete(position);
                end
            end
            default: expected_fault = 1;
        endcase
        expected_head = data_model.size() ? address_model[0] : cfg.MAX_NODE;
        expected_tail = data_model.size() ? address_model[$] : cfg.MAX_NODE;
        if (item.fault != expected_fault)
            `uvm_error("FAULT", $sformatf("op=%s addr=%0d expected=%0b actual=%0b", item.op.name(), item.addr, expected_fault, item.fault))
        if (item.current_len != data_model.size() || item.current_head != expected_head || item.current_tail != expected_tail)
            `uvm_error("STATE", $sformatf("Expected length/head/tail=%0d/%0d/%0d, actual=%0d/%0d/%0d", data_model.size(), expected_head, expected_tail, item.current_len, item.current_head, item.current_tail))
        if (item.full != (data_model.size() == cfg.MAX_NODE) || item.empty != (data_model.size() == 0))
            `uvm_error("FLAGS", "Full/empty differs from model occupancy")
        if (item.result_data != last_data || item.result_next_addr != last_next)
            `uvm_error("READ", $sformatf("Read/held outputs differ: expected data/next=%0h/%0d, actual=%0h/%0d", last_data, last_next, item.result_data, item.result_next_addr))
    endfunction

    function void report_phase(uvm_phase phase);
        if (checked_transactions == 0)
            `uvm_fatal("EMPTY_TEST", "No completed transactions checked")
        `uvm_info("RESULT", $sformatf("VIP PASSED: %0d transactions", checked_transactions), UVM_LOW)
    endfunction
endclass
