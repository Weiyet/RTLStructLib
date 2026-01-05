//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_sort_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sort sequences for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_sort_asc_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_sort_asc_seq)

    function new(string name = "list_vip_sort_asc_seq");
        super.new(name);
    endfunction

    task body();
        list_vip_seq_item item;

        item = list_vip_seq_item::type_id::create("item");
        if (cfg != null)
            item.cfg = cfg;

        start_item(item);
        assert(item.randomize() with {op == SORT_ASC;});
        finish_item(item);

        `uvm_info("SORT_ASC_SEQ", "Sort ascending completed", UVM_MEDIUM)
    endtask

endclass


class list_vip_sort_des_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_sort_des_seq)

    function new(string name = "list_vip_sort_des_seq");
        super.new(name);
    endfunction

    task body();
        list_vip_seq_item item;

        item = list_vip_seq_item::type_id::create("item");
        if (cfg != null)
            item.cfg = cfg;

        start_item(item);
        assert(item.randomize() with {op == SORT_DES;});
        finish_item(item);

        `uvm_info("SORT_DES_SEQ", "Sort descending completed", UVM_MEDIUM)
    endtask

endclass
