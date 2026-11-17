class priority_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(priority_vip_seq_item)
    rand bit [1:0] op;
    rand pq_priority_t priority_value;
    rand pq_data_t data;
    int unsigned stalls = 0;
    bit reset = 0;
    int abort_after = -1;
    bit aborted = 0;
    bit response_error;
    pq_priority_t response_priority;
    pq_data_t response_data;
    function new(string name="priority_vip_seq_item");
        super.new(name);
    endfunction
    function string convert2string();
        return $sformatf("op=%0d priority=%h data=%h stalls=%0d reset=%b abort_after=%0d",
                         op, priority_value, data, stalls, reset, abort_after);
    endfunction
endclass

// A fresh four-state observation for each clock, independent of driver items.
class priority_vip_sample extends uvm_sequence_item;
    `uvm_object_utils(priority_vip_sample)
    logic rst, req_valid, req_ready, rsp_valid, rsp_ready, rsp_error;
    logic [1:0] req_op;
    logic [PRIORITY_WIDTH-1:0] req_priority, rsp_priority;
    logic [DATA_WIDTH-1:0] req_data, rsp_data;
    logic [COUNT_WIDTH-1:0] count;
    logic full, empty;
    function new(string name="priority_vip_sample");
        super.new(name);
    endfunction
endclass
