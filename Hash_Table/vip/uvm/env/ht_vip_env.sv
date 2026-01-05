//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_env
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_env extends uvm_env;
    `uvm_component_utils(ht_vip_env)

    ht_vip_agent agent;
    ht_vip_scoreboard scoreboard;
    ht_vip_config cfg;

    function new(string name = "ht_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(ht_vip_config)::get(this, "", "ht_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")

        uvm_config_db#(ht_vip_config)::set(this, "agent", "ht_vip_cfg", cfg);
        uvm_config_db#(ht_vip_config)::set(this, "scoreboard", "ht_vip_cfg", cfg);

        agent = ht_vip_agent::type_id::create("agent", this);
        scoreboard = ht_vip_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction

    function ht_vip_sequencer get_sequencer();
        return agent.sequencer;
    endfunction

endclass
