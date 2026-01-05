//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_pop_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Pop sequence for LIFO VIP
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_pop_seq extends lifo_vip_base_seq;
    `uvm_object_utils(lifo_vip_pop_seq)

    rand int num_pops;

    constraint num_pops_c {
        num_pops inside {[1:100]};
    }

    function new(string name = "lifo_vip_pop_seq");
        super.new(name);
        num_pops = 10; // default
    endfunction

    task body();
        lifo_vip_seq_item item;

        for (int i = 0; i < num_pops; i++) begin
            item = lifo_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            assert(item.randomize() with {op == POP;});
            finish_item(item);

            `uvm_info("POP_SEQ", $sformatf("Pop #%0d: data=0x%0h", i, item.read_data), UVM_MEDIUM)
        end
    endtask

endclass
