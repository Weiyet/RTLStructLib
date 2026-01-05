//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_agent
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_agent extends uvm_agent;
    `uvm_component_utils(dll_vip_agent)

    dll_vip_driver driver;
    dll_vip_monitor monitor;
    dll_vip_sequencer sequencer;
    uvm_analysis_port #(dll_vip_seq_item) ap;

    function new(string name = "dll_vip_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = dll_vip_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            driver = dll_vip_driver::type_id::create("driver", this);
            sequencer = dll_vip_sequencer::type_id::create("sequencer", this);
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
