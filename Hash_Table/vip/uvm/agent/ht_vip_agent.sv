//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_agent
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_agent extends uvm_agent;
    `uvm_component_utils(ht_vip_agent)

    ht_vip_driver driver;
    ht_vip_monitor monitor;
    ht_vip_sequencer sequencer;
    uvm_analysis_port #(ht_vip_seq_item) ap;

    function new(string name = "ht_vip_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = ht_vip_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            driver = ht_vip_driver::type_id::create("driver", this);
            sequencer = ht_vip_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = monitor.ap;
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
