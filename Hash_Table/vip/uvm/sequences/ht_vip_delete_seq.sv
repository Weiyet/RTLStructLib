//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_delete_seq
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_delete_seq extends ht_vip_base_seq;
    `uvm_object_utils(ht_vip_delete_seq)

    rand int num_deletes;
    constraint num_deletes_c { num_deletes inside {[1:30]}; }

    function new(string name = "ht_vip_delete_seq");
        super.new(name);
    endfunction

    task body();
        ht_vip_seq_item item;

        for (int i = 0; i < num_deletes; i++) begin
            item = ht_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == DELETE;
                key inside {[1:1000]};
            });
            finish_item(item);
        end
    endtask

endclass
