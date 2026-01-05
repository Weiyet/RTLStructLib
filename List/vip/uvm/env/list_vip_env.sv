//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_env
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Environment containing agent and scoreboard
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_env extends uvm_env;
    `uvm_component_utils(list_vip_env)

    list_vip_config cfg;
    list_vip_agent agent;
    list_vip_scoreboard sb;

    function new(string name = "list_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(list_vip_config)::get(this, "", "list_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")

        // Set config for all components
        uvm_config_db#(list_vip_config)::set(this, "*", "list_vip_cfg", cfg);

        // Create agent
        if (cfg.has_agent) begin
            agent = list_vip_agent::type_id::create("agent", this);
        end

        // Create scoreboard
        if (cfg.enable_scoreboard) begin
            sb = list_vip_scoreboard::type_id::create("sb", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (cfg.enable_scoreboard && sb != null && agent != null) begin
            agent.ap.connect(sb.imp);
        end
    endfunction

    // Helper function for tests
    function list_vip_sequencer get_sequencer();
        return (agent != null) ? agent.sequencer : null;
    endfunction

endclass
