//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_config
// Description: Configuration class for Doubly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_config extends uvm_object;
    `uvm_object_utils(dll_vip_config)

    int DATA_WIDTH = 8;
    int MAX_NODE = 8;

    bit has_agent = 1;
    bit enable_scoreboard = 1;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "dll_vip_config");
        super.new(name);
    endfunction

endclass
