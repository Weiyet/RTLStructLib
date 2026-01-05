//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_find_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Find (search) sequences for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_find_1st_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_find_1st_seq)

    rand bit [31:0] search_value;
    rand int num_searches;

    constraint num_searches_c {
        num_searches inside {[1:10]};
    }

    function new(string name = "list_vip_find_1st_seq");
        super.new(name);
        num_searches = 3; // default
    endfunction

    task body();
        list_vip_seq_item item;

        for (int i = 0; i < num_searches; i++) begin
            item = list_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            assert(item.randomize() with {op == FIND_1ST;});
            finish_item(item);

            `uvm_info("FIND_1ST_SEQ", $sformatf("Search #%0d: value=0x%0h result_index=%0d", i, item.data, item.result_data), UVM_MEDIUM)
        end
    endtask

endclass


class list_vip_find_all_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_find_all_seq)

    rand bit [31:0] search_value;
    rand int num_searches;

    constraint num_searches_c {
        num_searches inside {[1:5]};
    }

    function new(string name = "list_vip_find_all_seq");
        super.new(name);
        num_searches = 2; // default
    endfunction

    task body();
        list_vip_seq_item item;

        for (int i = 0; i < num_searches; i++) begin
            item = list_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            assert(item.randomize() with {op == FIND_ALL;});
            finish_item(item);

            `uvm_info("FIND_ALL_SEQ", $sformatf("Search #%0d: value=0x%0h", i, item.data), UVM_MEDIUM)
        end
    endtask

endclass
