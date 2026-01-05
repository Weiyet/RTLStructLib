//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_config
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Configuration class for Singly Linked List VIP
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_config extends uvm_object;
    `uvm_object_utils(list_vip_config)

    // DUT parameters
    int DATA_WIDTH = 8;
    int LENGTH = 8;          // Maximum list length
    int SUM_METHOD = 0;      // 0: parallel, 1: sequential, 2: adder tree

    // VIP configuration
    bit has_agent = 1;
    bit enable_scoreboard = 1;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "list_vip_config");
        super.new(name);
    endfunction

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("DATA_WIDTH", DATA_WIDTH, 32, UVM_DEC);
        printer.print_field("LENGTH", LENGTH, 32, UVM_DEC);
        printer.print_field("SUM_METHOD", SUM_METHOD, 32, UVM_DEC);
        printer.print_field("has_agent", has_agent, 1, UVM_BIN);
        printer.print_field("enable_scoreboard", enable_scoreboard, 1, UVM_BIN);
    endfunction

endclass
