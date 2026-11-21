class bitmap_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(bitmap_vip_seq_item)
    bit rst, alloc_req, free_req;
    bit [ID_WIDTH-1:0] free_id;
    logic alloc_valid, alloc_error, free_valid, free_error, exhausted, all_free;
    logic [ID_WIDTH-1:0] alloc_id;
    logic [COUNT_WIDTH-1:0] free_count;
    function new(string name = "bitmap_vip_seq_item"); super.new(name); endfunction
endclass
