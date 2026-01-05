//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_agent
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Agent wrapper containing driver, monitor, and sequencer
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_agent extends uvm_agent;
    `uvm_component_utils(list_vip_agent)

    list_vip_driver driver;
    list_vip_monitor monitor;
    list_vip_sequencer sequencer;

    uvm_analysis_port #(list_vip_seq_item) ap;

    function new(string name = "list_vip_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = list_vip_monitor::type_id::create("monitor", this);

        if (is_active == UVM_ACTIVE) begin
            driver = list_vip_driver::type_id::create("driver", this);
            sequencer = list_vip_sequencer::type_id::create("sequencer", this);
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
