//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_read_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Read sequence for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_read_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_read_seq)

    rand int num_reads;
    rand bit sequential;  // If 1, read sequentially; if 0, random indices

    constraint num_reads_c {
        num_reads inside {[1:20]};
    }

    function new(string name = "list_vip_read_seq");
        super.new(name);
        num_reads = 5; // default
        sequential = 1;
    endfunction

    task body();
        list_vip_seq_item item;

        for (int i = 0; i < num_reads; i++) begin
            item = list_vip_seq_item::type_id::create("item");
            if (cfg != null)
                item.cfg = cfg;

            start_item(item);
            if (sequential) begin
                assert(item.randomize() with {op == READ; index == i;});
            end else begin
                assert(item.randomize() with {op == READ;});
            end
            finish_item(item);

            `uvm_info("READ_SEQ", $sformatf("Read #%0d: index=%0d data=0x%0h", i, item.index, item.result_data), UVM_MEDIUM)
        end
    endtask

endclass
