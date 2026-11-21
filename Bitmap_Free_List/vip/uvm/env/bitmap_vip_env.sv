class bitmap_vip_env extends uvm_env;
    `uvm_component_utils(bitmap_vip_env)
    bitmap_vip_agent agent;
    bitmap_vip_scoreboard scoreboard;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        agent = bitmap_vip_agent::type_id::create("agent", this);
        scoreboard = bitmap_vip_scoreboard::type_id::create("scoreboard", this);
    endfunction
    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.analysis_export);
    endfunction
endclass
