class priority_vip_driver extends uvm_driver #(priority_vip_seq_item);
    `uvm_component_utils(priority_vip_driver)
    priority_vip_config cfg;
    virtual priority_vip_if vif;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(priority_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing priority VIP config")
        vif = cfg.vif;
        if (vif == null) `uvm_fatal("CONFIG", "Missing virtual interface")
    endfunction
    task reset_bus();
        vif.req_valid = 0;
        vif.rsp_ready = 0;
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        @(negedge vif.clk);
    endtask
    task drive(priority_vip_seq_item item);
        int unsigned cycles;
        @(negedge vif.clk);
        if (item.reset) begin
            reset_bus();
            return;
        end
        cycles = 0;
        while (vif.req_ready !== 1 || vif.rst !== 0) begin
            @(negedge vif.clk);
            if (++cycles > cfg.timeout_cycles) `uvm_fatal("TIMEOUT", "Request timed out")
        end
        vif.req_op = item.op;
        vif.req_priority = item.priority_value;
        vif.req_data = item.data;
        vif.req_valid = 1;
        vif.rsp_ready = 0;
        @(vif.mon_cb);
        if (vif.mon_cb.req_ready !== 1) `uvm_fatal("REQUEST", "Request not accepted")
        @(negedge vif.clk);
        vif.req_valid = 0;
        if (item.abort_after >= 0) begin
            repeat (item.abort_after) @(negedge vif.clk);
            reset_bus();
            item.aborted = 1;
            return;
        end
        cycles = 0;
        while (vif.rsp_valid !== 1) begin
            if (vif.rst) begin
                item.aborted = 1;
                return;
            end
            @(negedge vif.clk);
            if (++cycles > cfg.timeout_cycles) `uvm_fatal("TIMEOUT", "Response timed out")
        end
        repeat (item.stalls) @(negedge vif.clk);
        if (vif.rst) begin
            item.aborted = 1;
            return;
        end
        item.response_error = vif.rsp_error;
        item.response_priority = vif.rsp_priority;
        item.response_data = vif.rsp_data;
        vif.rsp_ready = 1;
        @(vif.mon_cb);
        if (vif.mon_cb.rst) item.aborted = 1;
        else if (vif.mon_cb.rsp_valid !== 1) `uvm_fatal("RESPONSE", "Response not accepted")
        @(negedge vif.clk);
        vif.rsp_ready = 0;
    endtask
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive(req);
            seq_item_port.item_done();
        end
    endtask
endclass
