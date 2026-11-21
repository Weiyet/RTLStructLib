class bitmap_vip_base_test extends uvm_test;
    `uvm_component_utils(bitmap_vip_base_test)
    bitmap_vip_config cfg;
    bitmap_vip_env env;
    string scenario = "boundary";
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(bitmap_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing bitmap VIP config")
        if (scenario == "passive") cfg.is_active = UVM_PASSIVE;
        env = bitmap_vip_env::type_id::create("env", this);
    endfunction
    task external_cycle(bit a, bit f, int id, bit reset);
        @(negedge cfg.vif.clk);
        cfg.vif.rst = reset; cfg.vif.alloc_req = a; cfg.vif.free_req = f;
        cfg.vif.free_id = ID_WIDTH'(id);
        @(posedge cfg.vif.clk); #2ns;
        cfg.vif.rst = 0; cfg.vif.alloc_req = 0; cfg.vif.free_req = 0;
    endtask
    task run_phase(uvm_phase phase);
        bitmap_vip_sequence seq;
        phase.raise_objection(this);
        if (scenario == "passive") begin
            if (env.agent.driver != null || env.agent.sequencer != null)
                `uvm_fatal("PASSIVE", "Passive agent must not drive")
            external_cycle(1, 1, 0, 1);
            repeat (CAPACITY+1) external_cycle(1, 0, 0, 0);
            for (int i = 0; i < CAPACITY; i++) external_cycle(1, 1, i, 0);
            for (int i = 0; i < CAPACITY; i++) external_cycle(0, 1, i, 0);
        end else if (scenario != "empty") begin
            seq = bitmap_vip_sequence::type_id::create("seq");
            seq.scenario = scenario;
            seq.start(env.agent.sequencer);
        end
        repeat (2) @(negedge cfg.vif.clk);
        if (env.scoreboard.owned.num() != 0) `uvm_error("DRAIN", "Scenario did not release all IDs")
        phase.drop_objection(this);
    endtask
endclass

class bitmap_vip_boundary_test extends bitmap_vip_base_test;
    `uvm_component_utils(bitmap_vip_boundary_test)
    function new(string name, uvm_component parent);
        super.new(name, parent); scenario = "boundary";
    endfunction
endclass

class bitmap_vip_random_test extends bitmap_vip_base_test;
    `uvm_component_utils(bitmap_vip_random_test)
    function new(string name, uvm_component parent);
        super.new(name, parent); scenario = "random";
    endfunction
endclass

class bitmap_vip_reset_test extends bitmap_vip_base_test;
    `uvm_component_utils(bitmap_vip_reset_test)
    function new(string name, uvm_component parent);
        super.new(name, parent); scenario = "reset";
    endfunction
endclass

class bitmap_vip_passive_test extends bitmap_vip_base_test;
    `uvm_component_utils(bitmap_vip_passive_test)
    function new(string name, uvm_component parent);
        super.new(name, parent); scenario = "passive";
    endfunction
endclass

class bitmap_vip_empty_test extends bitmap_vip_base_test;
    `uvm_component_utils(bitmap_vip_empty_test)
    function new(string name, uvm_component parent);
        super.new(name, parent); scenario = "empty";
    endfunction
endclass
