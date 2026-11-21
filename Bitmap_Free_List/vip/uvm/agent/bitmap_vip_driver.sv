class bitmap_vip_driver extends uvm_driver #(bitmap_vip_seq_item);
    `uvm_component_utils(bitmap_vip_driver)
    bitmap_vip_config cfg;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(bitmap_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing bitmap VIP config")
        if (cfg.vif == null) `uvm_fatal("CONFIG", "Missing interface")
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            @(negedge cfg.vif.clk);
            cfg.vif.rst = req.rst;
            cfg.vif.alloc_req = req.alloc_req;
            cfg.vif.free_req = req.free_req;
            cfg.vif.free_id = req.free_id;
            @(posedge cfg.vif.clk);
            #2ns;
            req.alloc_valid = cfg.vif.alloc_valid;
            req.alloc_error = cfg.vif.alloc_error;
            req.alloc_id = cfg.vif.alloc_id;
            req.free_valid = cfg.vif.free_valid;
            req.free_error = cfg.vif.free_error;
            req.free_count = cfg.vif.free_count;
            req.exhausted = cfg.vif.exhausted;
            req.all_free = cfg.vif.all_free;
            cfg.vif.alloc_req = 0;
            cfg.vif.free_req = 0;
            cfg.vif.rst = 0;
            seq_item_port.item_done();
        end
    endtask
endclass
