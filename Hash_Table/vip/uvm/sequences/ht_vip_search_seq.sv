//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_search_seq
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_search_seq extends ht_vip_base_seq;
    `uvm_object_utils(ht_vip_search_seq)

    rand int num_searches;
    constraint num_searches_c { num_searches inside {[1:50]}; }

    function new(string name = "ht_vip_search_seq");
        super.new(name);
    endfunction

    task body();
        ht_vip_seq_item item;

        for (int i = 0; i < num_searches; i++) begin
            item = ht_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == SEARCH;
                key inside {[1:1000]};
            });
            finish_item(item);
        end
    endtask

endclass
