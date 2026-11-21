class bitmap_vip_config extends uvm_object;
    `uvm_object_utils(bitmap_vip_config)
    virtual bitmap_vip_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned timeout_cycles = 20000;
    function new(string name = "bitmap_vip_config"); super.new(name); endfunction
endclass
