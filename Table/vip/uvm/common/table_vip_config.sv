//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_config
//////////////////////////////////////////////////////////////////////////////////

class table_vip_config extends uvm_object;
    `uvm_object_utils(table_vip_config)

    int TABLE_SIZE = 32;
    int DATA_WIDTH = 8;
    int INPUT_RATE = 2;
    int OUTPUT_RATE = 2;

    function new(string name = "table_vip_config");
        super.new(name);
    endfunction

endclass
