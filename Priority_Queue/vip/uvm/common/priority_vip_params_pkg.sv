`ifndef PQ_VIP_DEPTH
`define PQ_VIP_DEPTH 16
`endif
`ifndef PQ_VIP_PRIORITY_WIDTH
`define PQ_VIP_PRIORITY_WIDTH 8
`endif
`ifndef PQ_VIP_DATA_WIDTH
`define PQ_VIP_DATA_WIDTH 8
`endif
`ifndef PQ_VIP_MIN_FIRST
`define PQ_VIP_MIN_FIRST 1
`endif
package priority_vip_params_pkg;
    parameter int DEPTH = `PQ_VIP_DEPTH;
    parameter int PRIORITY_WIDTH = `PQ_VIP_PRIORITY_WIDTH;
    parameter int DATA_WIDTH = `PQ_VIP_DATA_WIDTH;
    parameter int MIN_FIRST = `PQ_VIP_MIN_FIRST;
    parameter int COUNT_WIDTH = DEPTH < 2 ? 1 : $clog2(DEPTH+1);
    typedef bit [PRIORITY_WIDTH-1:0] pq_priority_t;
    typedef bit [DATA_WIDTH-1:0] pq_data_t;
    typedef struct packed {
        pq_priority_t priority_value;
        pq_data_t data;
    } pq_entry_t;
endpackage
