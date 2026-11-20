//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_simple_test
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        table_vip_write_seq write_seq;
        table_vip_read_seq read_seq;

        phase.raise_objection(this);
        `uvm_info("SIMPLE_TEST", "Starting simple table test", UVM_LOW)

        write_seq = table_vip_write_seq::type_id::create("write_seq");
        write_seq.num_writes = 10;
        write_seq.start(env.get_sequencer());

        #500ns;

        read_seq = table_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 10;
        read_seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("SIMPLE_TEST", "Simple test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class random_test extends base_test;
    `uvm_component_utils(random_test)

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        table_vip_write_seq write_seq;
        table_vip_read_seq read_seq;
        int op_sel;

        phase.raise_objection(this);
        `uvm_info("RANDOM_TEST", "Starting random test", UVM_LOW)

        write_seq = table_vip_write_seq::type_id::create("init_write");
        write_seq.num_writes = 15;
        write_seq.start(env.get_sequencer());

        #300ns;

        for (int i = 0; i < 20; i++) begin
            op_sel = $urandom_range(0, 1);
            case (op_sel)
                0: begin
                    write_seq = table_vip_write_seq::type_id::create($sformatf("write_%0d", i));
                    write_seq.num_writes = $urandom_range(1, 3);
                    write_seq.start(env.get_sequencer());
                end
                1: begin
                    read_seq = table_vip_read_seq::type_id::create($sformatf("read_%0d", i));
                    read_seq.num_reads = $urandom_range(2, 5);
                    read_seq.start(env.get_sequencer());
                end
            endcase
            #($urandom_range(100, 300));
        end

        #500ns;
        `uvm_info("RANDOM_TEST", "Random test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class parallel_access_test extends base_test;
    `uvm_component_utils(parallel_access_test)

    function new(string name = "parallel_access_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        table_vip_write_seq write_seq;
        table_vip_read_seq read_seq;

        phase.raise_objection(this);
        `uvm_info("PARALLEL_ACCESS_TEST", "Starting parallel access test", UVM_LOW)

        // Fill table with writes (2 writes per transaction)
        write_seq = table_vip_write_seq::type_id::create("parallel_write");
        write_seq.num_writes = 20;
        write_seq.start(env.get_sequencer());

        #500ns;

        // Read back with parallel reads (2 reads per transaction)
        read_seq = table_vip_read_seq::type_id::create("parallel_read");
        read_seq.num_reads = 20;
        read_seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("PARALLEL_ACCESS_TEST", "Parallel access test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class table_vip_boundary_seq extends table_vip_base_seq;
    `uvm_object_utils(table_vip_boundary_seq)
    table_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(bit [1:0] wr, bit rd, int index, int data0, int data1);
        table_vip_seq_item item = table_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = wr ? WRITE : READ; item.wr_en = wr; item.rd_en = rd; item.index_wr[0] = index; item.index_wr[1] = index; item.index_rd[0] = index; item.index_rd[1] = index; item.data_wr[0] = data0; item.data_wr[1] = data1;
        finish_item(item);
    endtask
    task reset_dut();
        virtual table_vip_if vif;
        if (!uvm_config_db#(virtual table_vip_if)::get(m_sequencer, "", "table_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(table_vip_config)::get(m_sequencer, "", "table_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        for (int i=0; i<32; i++) send(3, 1, i, i, 255-i);
        for (int i=0; i<32; i++) send(0, 1, i, 0, 0);
        send(1, 1, 0, 8'ha5, 0);
        send(2, 1, 31, 0, 8'h5a);
        send(0, 0, 4, 0, 0);
        reset_dut();
        send(0, 1, 0, 0, 0);
        send(0, 1, 31, 0, 0);
        send(3, 1, 7, 1, 2);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        table_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = table_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
