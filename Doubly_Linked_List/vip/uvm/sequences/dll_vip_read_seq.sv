//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_read_seq
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_read_seq extends dll_vip_base_seq;
    `uvm_object_utils(dll_vip_read_seq)

    rand int num_reads;

    constraint num_reads_c { num_reads inside {[1:10]}; }

    function new(string name = "dll_vip_read_seq");
        super.new(name);
        num_reads = 5;
    endfunction

    task body();
        dll_vip_seq_item item;
        for (int i = 0; i < num_reads; i++) begin
            item = dll_vip_seq_item::type_id::create("item");
            if (cfg != null) item.cfg = cfg;
            start_item(item);
            assert(item.randomize() with {op == READ_ADDR;});
            finish_item(item);
            `uvm_info("READ_SEQ", $sformatf("Read #%0d: addr=%0d data=0x%0h", i, item.addr, item.result_data), UVM_MEDIUM)
        end
    endtask

endclass
