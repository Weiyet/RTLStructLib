class priority_vip_env extends uvm_env;
    `uvm_component_utils(priority_vip_env)
    priority_vip_agent agent;
    priority_vip_scoreboard scoreboard;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = priority_vip_agent::type_id::create("agent", this);
        scoreboard = priority_vip_scoreboard::type_id::create("scoreboard", this);
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.analysis_export);
    endfunction
endclass
