//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_insert_seq
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_insert_seq extends ht_vip_base_seq;
    `uvm_object_utils(ht_vip_insert_seq)

    rand int num_inserts;
    constraint num_inserts_c { num_inserts inside {[1:50]}; }

    function new(string name = "ht_vip_insert_seq");
        super.new(name);
    endfunction

    task body();
        ht_vip_seq_item item;

        for (int i = 0; i < num_inserts; i++) begin
            item = ht_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == INSERT;
                key inside {[1:1000]};
                value inside {[1:65535]};
            });
            finish_item(item);
        end
    endtask

endclass
