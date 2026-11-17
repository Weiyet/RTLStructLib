typedef uvm_sequencer #(priority_vip_seq_item) priority_vip_sequencer;
class priority_vip_agent extends uvm_agent;
    `uvm_component_utils(priority_vip_agent)
    priority_vip_config cfg;
    priority_vip_monitor monitor;
    priority_vip_driver driver;
    priority_vip_sequencer sequencer;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(priority_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing priority VIP config")
        monitor = priority_vip_monitor::type_id::create("monitor", this);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver = priority_vip_driver::type_id::create("driver", this);
            sequencer = priority_vip_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (driver != null) driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
