//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_config
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_config extends uvm_object;
    `uvm_object_utils(deff_vip_config)

    int DATA_WIDTH = 8;
    bit [7:0] RESET_VALUE = 8'h00;

    function new(string name = "deff_vip_config");
        super.new(name);
    endfunction

endclass
