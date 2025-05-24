//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:04 PM
// Module Name: fifo_vip_read_req_seq
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This sequence generates read requests for the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_read_req_seq extends fifo_vip_base_seq;
    `uvm_object_utils(fifo_vip_read_req_seq)
    
    rand int num_reads;
    
    constraint num_reads_c {
        num_reads inside {[1:20]};
    }
    
    function new(string name = "fifo_vip_read_req_seq");
        super.new(name);
    endfunction
    
    task body();
        fifo_vip_seq_item item;
        
        `uvm_info("RD_SEQ", $sformatf("Starting %0d reads", num_reads), UVM_MEDIUM)
        
        repeat(num_reads) begin
            item = fifo_vip_seq_item::type_id::create("item");
            start_item(item);
            assert(item.randomize() with {op == READ;});
            finish_item(item);
        end
    endtask

endclass