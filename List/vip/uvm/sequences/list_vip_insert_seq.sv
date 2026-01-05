//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_insert_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Insert sequence for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_insert_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_insert_seq)

    rand int num_inserts;
    rand bit random_index;  // If 1, randomize index; if 0, append at end

    constraint num_inserts_c {
        num_inserts inside {[1:20]};
    }

    function new(string name = "list_vip_insert_seq");
        super.new(name);
        num_inserts = 5; // default
        random_index = 0;
    endfunction

    task body();
        list_vip_seq_item item;

        for (int i = 0; i < num_inserts; i++) begin
            item = list_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            if (random_index) begin
                assert(item.randomize() with {op == INSERT;});
            end else begin
                assert(item.randomize() with {op == INSERT; index == 'hFFFF;}); // Large index = append
            end
            finish_item(item);

            `uvm_info("INSERT_SEQ", $sformatf("Insert #%0d: data=0x%0h index=%0d", i, item.data, item.index), UVM_MEDIUM)
        end
    endtask

endclass
