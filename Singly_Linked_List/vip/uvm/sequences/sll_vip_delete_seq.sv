//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_delete_seq
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_delete_value_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_delete_value_seq)

    rand int num_deletes;
    constraint num_deletes_c { num_deletes inside {[1:10]}; }

    function new(string name = "sll_vip_delete_value_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_deletes; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == DELETE_VALUE;
                data inside {[1:255]};
            });
            finish_item(item);
        end
    endtask

endclass

class sll_vip_delete_at_addr_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_delete_at_addr_seq)

    rand int num_deletes;
    constraint num_deletes_c { num_deletes inside {[1:10]}; }

    function new(string name = "sll_vip_delete_at_addr_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_deletes; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == DELETE_AT_ADDR;
                addr inside {[1:15]};
            });
            finish_item(item);
        end
    endtask

endclass

class sll_vip_delete_at_index_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_delete_at_index_seq)

    rand int num_deletes;
    constraint num_deletes_c { num_deletes inside {[1:10]}; }

    function new(string name = "sll_vip_delete_at_index_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_deletes; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == DELETE_AT_INDEX;
                addr inside {[0:15]};
            });
            finish_item(item);
        end
    endtask

endclass
