//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_base_test
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    dll_vip_env env;
    dll_vip_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = dll_vip_config::type_id::create("cfg");
        cfg.DATA_WIDTH = 8;
        cfg.MAX_NODE = 8;
        cfg.has_agent = 1;
        cfg.enable_scoreboard = 1;
        cfg.is_active = UVM_ACTIVE;

        uvm_config_db#(dll_vip_config)::set(this, "*", "dll_vip_cfg", cfg);
        env = dll_vip_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("BASE_TEST", "Starting base test", UVM_LOW)
        #1us;
        phase.drop_objection(this);
    endtask

endclass
