//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_base_test
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    deff_vip_env env;
    deff_vip_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = deff_vip_config::type_id::create("cfg");
        cfg.DATA_WIDTH = 8;
        cfg.RESET_VALUE = 8'h00;

        uvm_config_db#(deff_vip_config)::set(this, "*", "deff_vip_cfg", cfg);

        env = deff_vip_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
