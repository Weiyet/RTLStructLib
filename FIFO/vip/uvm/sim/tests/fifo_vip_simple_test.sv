//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 10:04 PM
// Module Name: fifo_vip_base_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the base test for the FIFO VIP.
//
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_vip_write_req_seq wr_seq;
        fifo_vip_read_req_seq rd_seq;

        phase.raise_objection(this);

        // Write some data
        wr_seq = fifo_vip_write_req_seq::type_id::create("wr_seq");
        wr_seq.num_writes = 8;
        wr_seq.start(env.get_wr_sequencer());

        #200ns;

        // Read it back
        rd_seq = fifo_vip_read_req_seq::type_id::create("rd_seq");
        rd_seq.num_reads = 8;
        rd_seq.start(env.get_rd_sequencer());

        #200ns;
        phase.drop_objection(this);
    endtask

endclass
// Full/empty rejection, wraparound, concurrent clocks, and reset with queued data.
class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        fifo_vip_write_req_seq wr;
        fifo_vip_read_req_seq rd;
        virtual fifo_vip_if vif;
        phase.raise_objection(this);
        if (!uvm_config_db#(virtual fifo_vip_if)::get(this, "", "fifo_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        wr = fifo_vip_write_req_seq::type_id::create("wr");
        rd = fifo_vip_read_req_seq::type_id::create("rd");
        wait (!vif.rst);
        repeat (4) @(negedge vif.wr_clk);
        rd.num_reads = 3;
        rd.start(env.get_rd_sequencer());
        repeat (3) begin
            wr.num_writes = cfg.DEPTH + 3;
            wr.start(env.get_wr_sequencer());
            repeat (4) @(negedge vif.rd_clk);
            if (!vif.fifo_full || vif.fifo_empty)
                `uvm_error("BOUNDARY", "Filled FIFO must report full and nonempty")
            rd.num_reads = cfg.DEPTH + 3;
            rd.start(env.get_rd_sequencer());
            repeat (4) @(negedge vif.wr_clk);
            if (!vif.fifo_empty || vif.fifo_full)
                `uvm_error("BOUNDARY", "Drained FIFO must report empty and nonfull")
        end
        wr.num_writes = 40;
        rd.num_reads = 40;
        fork
            wr.start(env.get_wr_sequencer());
            rd.start(env.get_rd_sequencer());
        join
        repeat (4) @(negedge vif.rd_clk);
        rd.num_reads = cfg.DEPTH + 2;
        rd.start(env.get_rd_sequencer());
        wr.num_writes = 5;
        wr.start(env.get_wr_sequencer());
        @(negedge vif.wr_clk);
        vif.rst = 1;
        repeat (4) @(negedge vif.wr_clk);
        vif.rst = 0;
        repeat (4) @(negedge vif.wr_clk);
        rd.num_reads = 2;
        rd.start(env.get_rd_sequencer());
        wr.num_writes = 8;
        wr.start(env.get_wr_sequencer());
        repeat (4) @(negedge vif.rd_clk);
        rd.num_reads = 8;
        rd.start(env.get_rd_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
