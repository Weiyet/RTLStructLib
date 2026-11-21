class bitmap_vip_monitor extends uvm_monitor;
    `uvm_component_utils(bitmap_vip_monitor)
    bitmap_vip_config cfg;
    uvm_analysis_port #(bitmap_vip_seq_item) ap;
    function new(string name, uvm_component parent);
        super.new(name, parent); ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(bitmap_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing bitmap VIP config")
        if (cfg.vif == null) `uvm_fatal("CONFIG", "Missing interface")
    endfunction
    task run_phase(uvm_phase phase);
        bitmap_vip_seq_item s;
        int cycles = 0;
        forever begin
            @(cfg.vif.mon_cb);
            s = bitmap_vip_seq_item::type_id::create("sample");
            s.rst = cfg.vif.mon_cb.rst;
            s.alloc_req = cfg.vif.mon_cb.alloc_req;
            s.free_req = cfg.vif.mon_cb.free_req;
            s.free_id = cfg.vif.mon_cb.free_id;
            #1ns;
            s.alloc_valid = cfg.vif.alloc_valid;
            s.alloc_error = cfg.vif.alloc_error;
            s.alloc_id = cfg.vif.alloc_id;
            s.free_valid = cfg.vif.free_valid;
            s.free_error = cfg.vif.free_error;
            s.free_count = cfg.vif.free_count;
            s.exhausted = cfg.vif.exhausted;
            s.all_free = cfg.vif.all_free;
            ap.write(s);
            if (++cycles > cfg.timeout_cycles) `uvm_fatal("TIMEOUT", "Bitmap VIP watchdog")
        end
    endtask
endclass
