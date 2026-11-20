//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_simple_test
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sll_vip_insert_at_addr_seq insert_seq;
        sll_vip_read_seq read_seq;
        sll_vip_delete_at_addr_seq delete_seq;

        phase.raise_objection(this);
        `uvm_info("SIMPLE_TEST", "Starting simple singly linked list test", UVM_LOW)

        insert_seq = sll_vip_insert_at_addr_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 5;
        insert_seq.start(env.get_sequencer());

        #500ns;

        read_seq = sll_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.start(env.get_sequencer());

        #500ns;

        delete_seq = sll_vip_delete_at_addr_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 2;
        delete_seq.start(env.get_sequencer());

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
        sll_vip_insert_at_index_seq insert_seq;
        sll_vip_read_seq read_seq;
        sll_vip_delete_at_index_seq delete_seq;
        int op_sel;

        phase.raise_objection(this);
        `uvm_info("RANDOM_TEST", "Starting random test", UVM_LOW)

        insert_seq = sll_vip_insert_at_index_seq::type_id::create("init_insert");
        insert_seq.num_inserts = 4;
        insert_seq.start(env.get_sequencer());

        #300ns;

        for (int i = 0; i < 10; i++) begin
            op_sel = $urandom_range(0, 2);
            case (op_sel)
                0: begin
                    insert_seq = sll_vip_insert_at_index_seq::type_id::create($sformatf("insert_%0d", i));
                    insert_seq.num_inserts = $urandom_range(1, 2);
                    insert_seq.start(env.get_sequencer());
                end
                1: begin
                    read_seq = sll_vip_read_seq::type_id::create($sformatf("read_%0d", i));
                    read_seq.num_reads = $urandom_range(1, 3);
                    read_seq.start(env.get_sequencer());
                end
                2: begin
                    delete_seq = sll_vip_delete_at_index_seq::type_id::create($sformatf("delete_%0d", i));
                    delete_seq.num_deletes = 1;
                    delete_seq.start(env.get_sequencer());
                end
            endcase
            #($urandom_range(200, 400));
        end

        #500ns;
        `uvm_info("RANDOM_TEST", "Random test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class sll_vip_boundary_seq extends sll_vip_base_seq;
    `uvm_object_utils(sll_vip_boundary_seq)
    sll_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(sll_op_e op, int data, int addr);
        sll_vip_seq_item item = sll_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = op; item.data = data; item.addr = addr;
        finish_item(item);
    endtask
    task reset_dut();
        virtual sll_vip_if vif;
        if (!uvm_config_db#(virtual sll_vip_if)::get(m_sequencer, "", "sll_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(sll_vip_config)::get(m_sequencer, "", "sll_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        send(READ_ADDR, 0, 0);
        send(DELETE_AT_INDEX, 0, 0);
        for (int i=0; i<cfg.MAX_NODE; i++) send(INSERT_AT_INDEX, 8'h40+i, cfg.MAX_NODE);
        send(INSERT_AT_INDEX, 99, 0);
        for (int i=0; i<cfg.MAX_NODE; i++) send(READ_ADDR, 0, i);
        send(DELETE_AT_INDEX, 0, 0);
        send(INSERT_AT_INDEX, 8'hff, 0);
        send(READ_ADDR, 0, 0);
        send(DELETE_AT_ADDR, 0, 1);
        send(INSERT_AT_ADDR, 8'h80, 0);
        send(DELETE_VALUE, 8'h80, 0);
        send(INSERT_AT_ADDR, 8'hff, cfg.MAX_NODE);
        send(DELETE_VALUE, 8'hff, 0);
        for (int i=0; i<cfg.MAX_NODE; i++) send(READ_ADDR, 0, i);
        send(DELETE_VALUE, 8'hfe, 0);
        send(DELETE_AT_ADDR, 0, cfg.MAX_NODE);
        reset_dut();
        send(READ_ADDR, 0, 0);
        send(INSERT_AT_INDEX, 8'ha5, 0);
        send(READ_ADDR, 0, 0);
        send(DELETE_AT_ADDR, 0, 0);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        sll_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = sll_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
