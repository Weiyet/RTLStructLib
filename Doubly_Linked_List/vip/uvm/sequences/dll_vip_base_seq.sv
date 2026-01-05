//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_base_seq
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_base_seq extends uvm_sequence #(dll_vip_seq_item);
    `uvm_object_utils(dll_vip_base_seq)

    dll_vip_config cfg;

    function new(string name = "dll_vip_base_seq");
        super.new(name);
    endfunction

    task pre_body();
        if (!uvm_config_db#(dll_vip_config)::get(null, get_full_name(), "dll_vip_cfg", cfg))
            `uvm_warning("BASE_SEQ", "No config found, using defaults")
    endtask

endclass
