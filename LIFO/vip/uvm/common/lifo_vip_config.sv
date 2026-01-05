//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_config
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Configuration class for LIFO VIP
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_config extends uvm_object;
    `uvm_object_utils(lifo_vip_config)

    // DUT parameters
    int DEPTH = 12;
    int DATA_WIDTH = 8;

    // VIP configuration
    bit has_agent = 1;
    bit enable_scoreboard = 1;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "lifo_vip_config");
        super.new(name);
    endfunction

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("DEPTH", DEPTH, 32, UVM_DEC);
        printer.print_field("DATA_WIDTH", DATA_WIDTH, 32, UVM_DEC);
        printer.print_field("has_agent", has_agent, 1, UVM_BIN);
        printer.print_field("enable_scoreboard", enable_scoreboard, 1, UVM_BIN);
    endfunction

endclass
