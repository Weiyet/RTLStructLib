//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_insert_seq
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_insert_at_addr_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_insert_at_addr_seq)

    rand int num_inserts;

    constraint num_inserts_c { num_inserts inside {[1:10]}; }

    function new(string name = "dll_vip_insert_at_addr_seq");
        super.new(name);
        num_inserts = 5;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_inserts; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == INSERT_AT_ADDR;});
            finish_item(item);
            `uvm_info("INSERT_ADDR_SEQ", $sformatf("Insert #%0d: data=0x%0h", i, item.data), UVM_MEDIUM)
        end
    endtask

endclass

class dll_vip_insert_at_index_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_insert_at_index_seq)

    rand int num_inserts;

    constraint num_inserts_c { num_inserts inside {[1:10]}; }

    function new(string name = "dll_vip_insert_at_index_seq");
        super.new(name);
        num_inserts = 5;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_inserts; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == INSERT_AT_INDEX;});
            finish_item(item);
            `uvm_info("INSERT_INDEX_SEQ", $sformatf("Insert #%0d: addr=%0d data=0x%0h", i, item.addr, item.data), UVM_MEDIUM)
        end
    endtask

endclass
