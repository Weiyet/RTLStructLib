class priority_vip_base_test extends uvm_test;
    `uvm_component_utils(priority_vip_base_test)
    priority_vip_env env;
    priority_vip_config cfg;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(priority_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing priority VIP config")
        env = priority_vip_env::type_id::create("env", this);
    endfunction
    virtual function priority_vip_base_seq make_sequence();
        return priority_vip_boundary_seq::type_id::create("sequence");
    endfunction
    task run_phase(uvm_phase phase);
        priority_vip_base_seq sequence_handle;
        phase.raise_objection(this);
        sequence_handle = make_sequence();
        sequence_handle.start(env.agent.sequencer);
        repeat (3) @(negedge cfg.vif.clk);
        if (env.scoreboard.occupancy != 0) `uvm_fatal("DRAIN", "Queue not drained")
        phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        super.report_phase(phase);
        server = uvm_report_server::get_server();
        if (server.get_severity_count(UVM_ERROR) || server.get_severity_count(UVM_FATAL))
            $fatal(1, "Priority VIP failed");
        $display("PRIORITY VIP PASSED: %0d responses", env.scoreboard.completed);
    endfunction
endclass

class priority_vip_boundary_test extends priority_vip_base_test;
    `uvm_component_utils(priority_vip_boundary_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
endclass

class priority_vip_random_test extends priority_vip_base_test;
    `uvm_component_utils(priority_vip_random_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function priority_vip_base_seq make_sequence();
        return priority_vip_random_seq::type_id::create("sequence");
    endfunction
endclass

class priority_vip_reset_test extends priority_vip_base_test;
    `uvm_component_utils(priority_vip_reset_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function priority_vip_base_seq make_sequence();
        return priority_vip_reset_seq::type_id::create("sequence");
    endfunction
endclass
