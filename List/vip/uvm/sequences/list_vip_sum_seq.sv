//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_sum_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sum sequence for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_sum_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_sum_seq)

    function new(string name = "list_vip_sum_seq");
        super.new(name);
    endfunction

    task body();
        list_vip_seq_item item;

        item = list_vip_seq_item::type_id::create("item");
        if (cfg != null)
            item.cfg = cfg;

        start_item(item);
        assert(item.randomize() with {op == SUM;});
        finish_item(item);

        `uvm_info("SUM_SEQ", $sformatf("Sum result=%0d", item.result_data), UVM_MEDIUM)
    endtask

endclass
