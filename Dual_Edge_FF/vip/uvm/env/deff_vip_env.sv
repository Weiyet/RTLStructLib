//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_env
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_env extends uvm_env;
    `uvm_component_utils(deff_vip_env)

    deff_vip_agent agent;
    deff_vip_scoreboard scoreboard;
    deff_vip_config cfg;

    function new(string name = "deff_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(deff_vip_config)::get(this, "", "deff_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")

        uvm_config_db#(deff_vip_config)::set(this, "agent", "deff_vip_cfg", cfg);
        uvm_config_db#(deff_vip_config)::set(this, "scoreboard", "deff_vip_cfg", cfg);

        agent = deff_vip_agent::type_id::create("agent", this);
        scoreboard = deff_vip_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction

    function deff_vip_sequencer get_sequencer();
        return agent.sequencer;
    endfunction

endclass
