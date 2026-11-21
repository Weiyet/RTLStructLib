`ifndef BITMAP_VIP_CAPACITY
`define BITMAP_VIP_CAPACITY 16
`endif
package bitmap_vip_params_pkg;
    localparam int CAPACITY = `BITMAP_VIP_CAPACITY;
    localparam int ID_WIDTH = (CAPACITY <= 1) ? 1 : $clog2(CAPACITY);
    localparam int COUNT_WIDTH = (CAPACITY < 1) ? 1 : $clog2(CAPACITY+1);
endpackage
