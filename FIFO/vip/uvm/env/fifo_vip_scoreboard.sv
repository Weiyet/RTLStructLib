//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:01 PM
// Module Name: fifo_vip_scoreboard.sv
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP scoreboard.
// 
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_vip_scoreboard)
    
    uvm_analysis_imp_wr #(fifo_vip_seq_item, fifo_vip_scoreboard) wr_imp;
    uvm_analysis_imp_rd #(fifo_vip_seq_item, fifo_vip_scoreboard) rd_imp;
    
    // Simple queue model
    int fifo_model[$];
    int errors = 0;
    
    function new(string name = "fifo_vip_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        wr_imp = new("wr_imp", this);
        rd_imp = new("rd_imp", this);
    endfunction
    
    function void write_wr(fifo_vip_seq_item item);
        if (item.op == WRITE && item.success) begin
            fifo_model.push_back(item.data);
            `uvm_info("SB", $sformatf("Write: data=0x%0h, queue_size=%0d", item.data, fifo_model.size()), UVM_MEDIUM)
        end
    endfunction
    
    function void write_rd(fifo_vip_seq_item item);
        if (item.op == READ && item.success) begin
            if (fifo_model.size() > 0) begin
                int expected = fifo_model.pop_front();
                if (item.read_data == expected) begin
                    `uvm_info("SB", $sformatf("Read OK: data=0x%0h, queue_size=%0d", item.read_data, fifo_model.size()), UVM_MEDIUM)
                end else begin
                    `uvm_error("SB", $sformatf("Data mismatch! Expected:0x%0h Got:0x%0h", expected, item.read_data))
                    errors++;
                end
            end else begin
                `uvm_error("SB", "Read from empty FIFO model")
                errors++;
            end
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        if (errors == 0)
            `uvm_info("SB", "*** TEST PASSED ***", UVM_LOW)
        else
            `uvm_error("SB", $sformatf("*** TEST FAILED - %0d errors ***", errors))
    endfunction

endclass