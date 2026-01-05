//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_config
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_config extends uvm_object;
    `uvm_object_utils(ht_vip_config)

    int KEY_WIDTH = 32;
    int VALUE_WIDTH = 32;
    int TOTAL_INDEX = 8;
    int CHAINING_SIZE = 4;
    string COLLISION_METHOD = "MULTI_STAGE_CHAINING";
    string HASH_ALGORITHM = "MODULUS";

    function new(string name = "ht_vip_config");
        super.new(name);
    endfunction

endclass
