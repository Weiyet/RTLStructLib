//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_push_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Push sequence for LIFO VIP
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_push_seq extends lifo_vip_base_seq;
    `uvm_object_utils(lifo_vip_push_seq)

    rand int num_pushes;

    constraint num_pushes_c {
        num_pushes inside {[1:100]};
    }

    function new(string name = "lifo_vip_push_seq");
        super.new(name);
        num_pushes = 10; // default
    endfunction

    task body();
        lifo_vip_seq_item item;

        for (int i = 0; i < num_pushes; i++) begin
            item = lifo_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            assert(item.randomize() with {op == PUSH;});
            finish_item(item);

            `uvm_info("PUSH_SEQ", $sformatf("Push #%0d: data=0x%0h", i, item.data), UVM_MEDIUM)
        end
    endtask

endclass
