class priority_vip_config extends uvm_object;
    `uvm_object_utils(priority_vip_config)
    virtual priority_vip_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned timeout_cycles = 100000;
    function new(string name="priority_vip_config");
        super.new(name);
    endfunction
endclass
