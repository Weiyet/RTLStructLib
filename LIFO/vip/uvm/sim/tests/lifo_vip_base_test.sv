//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_base_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Base test class for LIFO VIP tests
//
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    lifo_vip_env env;
    lifo_vip_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create and configure
        cfg = lifo_vip_config::type_id::create("cfg");
        cfg.DEPTH = 12;
        cfg.DATA_WIDTH = 8;
        cfg.has_agent = 1;
        cfg.enable_scoreboard = 1;
        cfg.is_active = UVM_ACTIVE;

        // Set in config DB
        uvm_config_db#(lifo_vip_config)::set(this, "*", "lifo_vip_cfg", cfg);

        // Create environment
        env = lifo_vip_env::type_id::create("env", this);
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
