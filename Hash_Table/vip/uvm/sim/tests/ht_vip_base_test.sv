//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_base_test
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    ht_vip_env env;
    ht_vip_config cfg;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = ht_vip_config::type_id::create("cfg");
        cfg.KEY_WIDTH = 32;
        cfg.VALUE_WIDTH = 32;
        cfg.TOTAL_INDEX = 8;
        cfg.CHAINING_SIZE = 4;
        cfg.COLLISION_METHOD = "MULTI_STAGE_CHAINING";
        cfg.HASH_ALGORITHM = "MODULUS";

        uvm_config_db#(ht_vip_config)::set(this, "*", "ht_vip_cfg", cfg);

        env = ht_vip_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
