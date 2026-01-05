//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_env
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_env extends uvm_env;
    `uvm_component_utils(dll_vip_env)

    dll_vip_config cfg;
    dll_vip_agent agent;
    dll_vip_scoreboard sb;

    function new(string name = "dll_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(dll_vip_config)::get(this, "", "dll_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")

        uvm_config_db#(dll_vip_config)::set(this, "*", "dll_vip_cfg", cfg);

        if (cfg.has_agent)
            agent = dll_vip_agent::type_id::create("agent", this);
        if (cfg.enable_scoreboard)
            sb = dll_vip_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.enable_scoreboard && sb != null && agent != null)
            agent.ap.connect(sb.imp);
    endfunction

    function dll_vip_sequencer get_sequencer();
        return (agent != null) ? agent.sequencer : null;
    endfunction

endclass
