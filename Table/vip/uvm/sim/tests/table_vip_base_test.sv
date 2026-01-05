//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_base_test
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    table_vip_env env;
    table_vip_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = table_vip_config::type_id::create("cfg");
        cfg.TABLE_SIZE = 32;
        cfg.DATA_WIDTH = 8;
        cfg.INPUT_RATE = 2;
        cfg.OUTPUT_RATE = 2;

        uvm_config_db#(table_vip_config)::set(this, "*", "table_vip_cfg", cfg);

        env = table_vip_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
