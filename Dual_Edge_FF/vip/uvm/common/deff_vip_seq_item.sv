//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_seq_item
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(deff_vip_seq_item)

    rand bit [7:0] data_in;
    rand bit [7:0] pos_edge_latch_en;
    rand bit [7:0] neg_edge_latch_en;

    bit [7:0] data_out;

    constraint valid_latch_c {
        // At least one latch enable should be active for meaningful transaction
        (pos_edge_latch_en | neg_edge_latch_en) != 8'h00;
    }

    function new(string name = "deff_vip_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("data_in=0x%0h pos_en=0x%0h neg_en=0x%0h data_out=0x%0h",
                        data_in, pos_edge_latch_en, neg_edge_latch_en, data_out);
    endfunction

    function void do_copy(uvm_object rhs);
        deff_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            `uvm_fatal("DO_COPY", "Cast failed")
        super.do_copy(rhs);
        data_in = rhs_.data_in;
        pos_edge_latch_en = rhs_.pos_edge_latch_en;
        neg_edge_latch_en = rhs_.neg_edge_latch_en;
        data_out = rhs_.data_out;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        deff_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            return 0;
        return (super.do_compare(rhs, comparer) &&
                (data_in == rhs_.data_in) &&
                (pos_edge_latch_en == rhs_.pos_edge_latch_en) &&
                (neg_edge_latch_en == rhs_.neg_edge_latch_en));
    endfunction

endclass
