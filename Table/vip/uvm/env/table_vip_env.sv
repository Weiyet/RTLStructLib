//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_env
//////////////////////////////////////////////////////////////////////////////////

class table_vip_env extends uvm_env;
    `uvm_component_utils(table_vip_env)

    table_vip_agent agent;
    table_vip_scoreboard scoreboard;
    table_vip_config cfg;

    function new(string name = "table_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(table_vip_config)::get(this, "", "table_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")

        uvm_config_db#(table_vip_config)::set(this, "agent", "table_vip_cfg", cfg);
        uvm_config_db#(table_vip_config)::set(this, "scoreboard", "table_vip_cfg", cfg);

        agent = table_vip_agent::type_id::create("agent", this);
        scoreboard = table_vip_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction

    function table_vip_sequencer get_sequencer();
        return agent.sequencer;
    endfunction

endclass
