module tb_top;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import priority_vip_params_pkg::*;
    import priority_vip_pkg::*;
    bit clk = 0;
    always #5 clk = ~clk;
    priority_vip_if bus(clk);
    priority_queue #(.DEPTH(DEPTH), .PRIORITY_WIDTH(PRIORITY_WIDTH),
                     .DATA_WIDTH(DATA_WIDTH), .MIN_FIRST(MIN_FIRST)) dut (
        .clk(clk), .rst(bus.rst),
        .req_valid(bus.req_valid), .req_ready(bus.req_ready), .req_op(bus.req_op),
        .req_priority(bus.req_priority), .req_data(bus.req_data),
        .rsp_valid(bus.rsp_valid), .rsp_ready(bus.rsp_ready), .rsp_error(bus.rsp_error),
        .rsp_priority(bus.rsp_priority), .rsp_data(bus.rsp_data),
        .count(bus.count), .full(bus.full), .empty(bus.empty)
    );
    initial begin
        priority_vip_config cfg;
        cfg = new("cfg");
        bus.rst = 1;
        bus.req_valid = 0;
        bus.req_op = 0;
        bus.req_priority = 0;
        bus.req_data = 0;
        bus.rsp_ready = 0;
        cfg.vif = bus;
        void'($value$plusargs("TB_TIMEOUT_CYCLES=%d", cfg.timeout_cycles));
        uvm_config_db#(priority_vip_config)::set(null, "uvm_test_top*", "cfg", cfg);
        run_test();
    end
endmodule
