//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_delete_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Delete sequence for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_delete_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_delete_seq)

    rand int num_deletes;

    constraint num_deletes_c {
        num_deletes inside {[1:10]};
    }

    function new(string name = "list_vip_delete_seq");
        super.new(name);
        num_deletes = 3; // default
    endfunction

    task body();
        list_vip_seq_item item;

        for (int i = 0; i < num_deletes; i++) begin
            item = list_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            assert(item.randomize() with {op == DELETE;});
            finish_item(item);

            `uvm_info("DELETE_SEQ", $sformatf("Delete #%0d: index=%0d", i, item.index), UVM_MEDIUM)
        end
    endtask

endclass
