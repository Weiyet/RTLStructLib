class priority_vip_monitor extends uvm_monitor;
    `uvm_component_utils(priority_vip_monitor)
    priority_vip_config cfg;
    virtual priority_vip_if vif;
    uvm_analysis_port #(priority_vip_sample) ap;
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(priority_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing priority VIP config")
        vif = cfg.vif;
        if (vif == null) `uvm_fatal("CONFIG", "Missing virtual interface")
    endfunction
    task run_phase(uvm_phase phase);
        priority_vip_sample s;
        int unsigned cycles = 0;
        forever begin
            @(vif.mon_cb);
            s = priority_vip_sample::type_id::create("sample");
            s.rst = vif.mon_cb.rst;
            s.req_valid = vif.mon_cb.req_valid;
            s.req_ready = vif.mon_cb.req_ready;
            s.req_op = vif.mon_cb.req_op;
            s.req_priority = vif.mon_cb.req_priority;
            s.req_data = vif.mon_cb.req_data;
            s.rsp_valid = vif.mon_cb.rsp_valid;
            s.rsp_ready = vif.mon_cb.rsp_ready;
            s.rsp_error = vif.mon_cb.rsp_error;
            s.rsp_priority = vif.mon_cb.rsp_priority;
            s.rsp_data = vif.mon_cb.rsp_data;
            s.count = vif.mon_cb.count;
            s.full = vif.mon_cb.full;
            s.empty = vif.mon_cb.empty;
            ap.write(s);
            if (++cycles > cfg.timeout_cycles) `uvm_fatal("TIMEOUT", "Priority VIP timed out")
        end
    endtask
endclass
