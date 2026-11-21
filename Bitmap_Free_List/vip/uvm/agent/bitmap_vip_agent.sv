typedef uvm_sequencer #(bitmap_vip_seq_item) bitmap_vip_sequencer;
class bitmap_vip_agent extends uvm_agent;
    `uvm_component_utils(bitmap_vip_agent)
    bitmap_vip_monitor monitor;
    bitmap_vip_driver driver;
    bitmap_vip_sequencer sequencer;
    bitmap_vip_config cfg;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(bitmap_vip_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("CONFIG", "Missing bitmap VIP config")
        monitor = bitmap_vip_monitor::type_id::create("monitor", this);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver = bitmap_vip_driver::type_id::create("driver", this);
            sequencer = bitmap_vip_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    function void connect_phase(uvm_phase phase);
        if (driver != null) driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
