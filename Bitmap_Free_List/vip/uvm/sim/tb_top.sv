module tb_top;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import bitmap_vip_params_pkg::*;
    import bitmap_vip_pkg::*;
    bit clk = 0;
    always #5 clk = ~clk;
    bitmap_vip_if bus(clk);
    bitmap_free_list #(.CAPACITY(CAPACITY)) dut (
        .clk(clk), .rst(bus.rst), .alloc_req(bus.alloc_req), .free_req(bus.free_req),
        .free_id(bus.free_id), .alloc_valid(bus.alloc_valid), .alloc_error(bus.alloc_error),
        .alloc_id(bus.alloc_id), .free_valid(bus.free_valid), .free_error(bus.free_error),
        .free_count(bus.free_count), .exhausted(bus.exhausted), .all_free(bus.all_free)
    );
    initial begin
        bitmap_vip_config cfg;
        cfg = new("cfg"); cfg.vif = bus;
        bus.rst = 1; bus.alloc_req = 0; bus.free_req = 0; bus.free_id = 0;
        void'($value$plusargs("TB_TIMEOUT_CYCLES=%d", cfg.timeout_cycles));
        uvm_config_db#(bitmap_vip_config)::set(null, "uvm_test_top*", "cfg", cfg);
        run_test();
    end
endmodule
