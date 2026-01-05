//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_base_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Base sequence for LIFO VIP
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_base_seq extends uvm_sequence #(lifo_vip_seq_item);
    `uvm_object_utils(lifo_vip_base_seq)

    lifo_vip_config cfg;

    function new(string name = "lifo_vip_base_seq");
        super.new(name);
    endfunction

    task pre_body();
        if (!uvm_config_db#(lifo_vip_config)::get(null, get_full_name(), "lifo_vip_cfg", cfg)) begin
            `uvm_warning("BASE_SEQ", "No config found, using defaults")
        end
    endtask

endclass
