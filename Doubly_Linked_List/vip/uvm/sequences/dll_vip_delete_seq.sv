//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_delete_seq
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_delete_at_addr_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_delete_at_addr_seq)

    rand int num_deletes;

    constraint num_deletes_c { num_deletes inside {[1:5]}; }

    function new(string name = "dll_vip_delete_at_addr_seq");
        super.new(name);
        num_deletes = 3;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_deletes; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == DELETE_AT_ADDR;});
            finish_item(item);
            `uvm_info("DELETE_ADDR_SEQ", $sformatf("Delete #%0d: addr=%0d", i, item.addr), UVM_MEDIUM)
        end
    endtask

endclass

class dll_vip_delete_at_index_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_delete_at_index_seq)

    rand int num_deletes;

    constraint num_deletes_c { num_deletes inside {[1:5]}; }

    function new(string name = "dll_vip_delete_at_index_seq");
        super.new(name);
        num_deletes = 3;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_deletes; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == DELETE_AT_INDEX;});
            finish_item(item);
            `uvm_info("DELETE_INDEX_SEQ", $sformatf("Delete #%0d: addr=%0d", i, item.addr), UVM_MEDIUM)
        end
    endtask

endclass

class dll_vip_delete_value_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_delete_value_seq)

    rand int num_deletes;

    constraint num_deletes_c { num_deletes inside {[1:3]}; }

    function new(string name = "dll_vip_delete_value_seq");
        super.new(name);
        num_deletes = 2;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_deletes; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == DELETE_VALUE;});
            finish_item(item);
            `uvm_info("DELETE_VALUE_SEQ", $sformatf("Delete #%0d: value=0x%0h", i, item.data), UVM_MEDIUM)
        end
    endtask

endclass
