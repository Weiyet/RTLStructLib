//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_read_seq
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_read_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_read_seq)

    rand int num_reads;
    constraint num_reads_c { num_reads inside {[1:20]}; }

    function new(string name = "sll_vip_read_seq");
        super.new(name);
    endfunction

    task body();
        sll_vip_seq_item item;

        for (int i = 0; i < num_reads; i++) begin
            item = sll_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == READ_ADDR;
                addr inside {[1:15]};
            });
            finish_item(item);
        end
    endtask

endclass
