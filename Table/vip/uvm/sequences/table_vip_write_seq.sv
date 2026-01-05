//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_write_seq
//////////////////////////////////////////////////////////////////////////////////

class table_vip_write_seq extends table_vip_base_seq;
    `uvm_object_utils(table_vip_write_seq)

    rand int num_writes;
    constraint num_writes_c { num_writes inside {[1:50]}; }

    function new(string name = "table_vip_write_seq");
        super.new(name);
    endfunction

    task body();
        table_vip_seq_item item;

        for (int i = 0; i < num_writes; i++) begin
            item = table_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                op == WRITE;
                wr_en != 2'b00;
            });
            finish_item(item);
        end
    endtask

endclass
