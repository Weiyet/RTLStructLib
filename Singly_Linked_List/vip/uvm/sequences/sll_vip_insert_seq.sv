//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_insert_seq
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_insert_at_addr_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_insert_at_addr_seq)

    rand int num_inserts;
    constraint num_inserts_c { num_inserts inside {[1:20]}; }

    function new(string name = "sll_vip_insert_at_addr_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_inserts; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == INSERT_AT_ADDR;
                data inside {[1:255]};
                addr inside {[0:15]};
            });
            finish_item(item);
        end
    endtask

endclass

class sll_vip_insert_at_index_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_insert_at_index_seq)

    rand int num_inserts;
    constraint num_inserts_c { num_inserts inside {[1:20]}; }

    function new(string name = "sll_vip_insert_at_index_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_inserts; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == INSERT_AT_INDEX;
                data inside {[1:255]};
                addr inside {[0:15]};
            });
            finish_item(item);
        end
    endtask

endclass
