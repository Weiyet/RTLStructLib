//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 08:57 PM
// Module Name: fifo_vip_env
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP environment.
// 
//////////////////////////////////////////////////////////////////////////////////
class fifo_vip_env extends uvm_env;
    `uvm_component_utils(fifo_vip_env)
    
    fifo_vip_config cfg;
    fifo_vip_agent wr_agent;
    fifo_vip_agent rd_agent;
    fifo_vip_scoreboard sb;
    
    function new(string name = "fifo_vip_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(fifo_vip_config)::get(this, "", "fifo_vip_cfg", cfg))
            `uvm_fatal("ENV", "No config")
        
        // Set config for all components
        uvm_config_db#(fifo_vip_config)::set(this, "*", "fifo_vip_cfg", cfg);
        
        // Create agents
        if (cfg.has_wr_agent) begin
            wr_agent = fifo_vip_agent::type_id::create("wr_agent", this);
        end
        
        if (cfg.has_rd_agent) begin
            rd_agent = fifo_vip_agent::type_id::create("rd_agent", this);
        end
        
        // Create scoreboard
        if (cfg.enable_scoreboard) begin
            sb = fifo_vip_scoreboard::type_id::create("sb", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (cfg.enable_scoreboard && sb != null) begin
            if (wr_agent != null) wr_agent.ap.connect(sb.wr_imp);
            if (rd_agent != null) rd_agent.ap.connect(sb.rd_imp);
        end
    endfunction
    
    // Helper functions for tests
    function fifo_vip_sequencer get_wr_sequencer();
        return (wr_agent != null) ? wr_agent.sequencer : null;
    endfunction
    
    function fifo_vip_sequencer get_rd_sequencer();
        return (rd_agent != null) ? rd_agent.sequencer : null;
    endfunction

endclass