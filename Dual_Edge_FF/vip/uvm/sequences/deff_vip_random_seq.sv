//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_random_seq
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_random_seq extends deff_vip_base_seq;
    `uvm_object_utils(deff_vip_random_seq)

    rand int num_items;
    constraint num_items_c { num_items inside {[10:100]}; }

    function new(string name = "deff_vip_random_seq");
        super.new(name);
    endfunction

    task body();
        deff_vip_seq_item item;

        for (int i = 0; i < num_items; i++) begin
            item = deff_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize());
            finish_item(item);
        end
    endtask

endclass

class deff_vip_pos_edge_only_seq extends deff_vip_base_seq;
    `uvm_object_utils(deff_vip_pos_edge_only_seq)

    rand int num_items;
    constraint num_items_c { num_items inside {[10:50]}; }

    function new(string name = "deff_vip_pos_edge_only_seq");
        super.new(name);
    endfunction

    task body();
        deff_vip_seq_item item;

        for (int i = 0; i < num_items; i++) begin
            item = deff_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                pos_edge_latch_en != 8'h00;
                neg_edge_latch_en == 8'h00;
            });
            finish_item(item);
        end
    endtask

endclass

class deff_vip_neg_edge_only_seq extends deff_vip_base_seq;
    `uvm_object_utils(deff_vip_neg_edge_only_seq)

    rand int num_items;
    constraint num_items_c { num_items inside {[10:50]}; }

    function new(string name = "deff_vip_neg_edge_only_seq");
        super.new(name);
    endfunction

    task body();
        deff_vip_seq_item item;

        for (int i = 0; i < num_items; i++) begin
            item = deff_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                pos_edge_latch_en == 8'h00;
                neg_edge_latch_en != 8'h00;
            });
            finish_item(item);
        end
    endtask

endclass

class deff_vip_dual_edge_seq extends deff_vip_base_seq;
    `uvm_object_utils(deff_vip_dual_edge_seq)

    rand int num_items;
    constraint num_items_c { num_items inside {[10:50]}; }

    function new(string name = "deff_vip_dual_edge_seq");
        super.new(name);
    endfunction

    task body();
        deff_vip_seq_item item;

        for (int i = 0; i < num_items; i++) begin
            item = deff_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {
                pos_edge_latch_en != 8'h00;
                neg_edge_latch_en != 8'h00;
            });
            finish_item(item);
        end
    endtask

endclass
