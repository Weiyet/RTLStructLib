//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_simple_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Simple test demonstrating list operations
//
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        list_vip_insert_seq insert_seq;
        list_vip_read_seq read_seq;
        list_vip_delete_seq delete_seq;
        list_vip_sum_seq sum_seq;

        phase.raise_objection(this);

        `uvm_info("SIMPLE_TEST", "Starting simple list test", UVM_LOW)

        // Insert some elements
        insert_seq = list_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 5;
        insert_seq.random_index = 0; // Append at end
        insert_seq.start(env.get_sequencer());

        #200ns;

        // Read them back
        read_seq = list_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.sequential = 1;
        read_seq.start(env.get_sequencer());

        #200ns;

        // Sum all elements
        sum_seq = list_vip_sum_seq::type_id::create("sum_seq");
        sum_seq.start(env.get_sequencer());

        #200ns;

        // Delete an element
        delete_seq = list_vip_delete_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 2;
        delete_seq.start(env.get_sequencer());

        #200ns;

        `uvm_info("SIMPLE_TEST", "Simple test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

//////////////////////////////////////////////////////////////////////////////////
// Direct operation test - mirrors tb.sv direct_op_test
//////////////////////////////////////////////////////////////////////////////////

class direct_op_test extends base_test;
    `uvm_component_utils(direct_op_test)

    function new(string name = "direct_op_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        list_vip_insert_seq insert_seq;
        list_vip_read_seq read_seq;
        list_vip_delete_seq delete_seq;
        list_vip_sum_seq sum_seq;
        list_vip_sort_asc_seq sort_asc_seq;
        list_vip_sort_des_seq sort_des_seq;
        list_vip_find_1st_seq find_1st_seq;

        phase.raise_objection(this);

        `uvm_info("DIRECT_OP_TEST", "Starting direct operation test", UVM_LOW)

        // Insert operations (similar to tb.sv lines 438-445)
        insert_seq = list_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 5;
        insert_seq.random_index = 0;
        insert_seq.start(env.get_sequencer());

        #500ns;

        // Read operations (tb.sv lines 448-453)
        read_seq = list_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 6; // Including out of bounds
        read_seq.sequential = 1;
        read_seq.start(env.get_sequencer());

        #500ns;

        // Delete operation (tb.sv lines 455-456)
        delete_seq = list_vip_delete_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 1;
        delete_seq.start(env.get_sequencer());

        #300ns;

        // Sum operation (tb.sv line 459)
        sum_seq = list_vip_sum_seq::type_id::create("sum_seq");
        sum_seq.start(env.get_sequencer());

        #300ns;

        // Sort ascending (tb.sv line 462)
        sort_asc_seq = list_vip_sort_asc_seq::type_id::create("sort_asc_seq");
        sort_asc_seq.start(env.get_sequencer());

        #500ns;

        // Read after sort (tb.sv line 464)
        read_seq = list_vip_read_seq::type_id::create("read_seq2");
        read_seq.num_reads = 5;
        read_seq.sequential = 1;
        read_seq.start(env.get_sequencer());

        #500ns;

        // Sort descending (tb.sv line 467)
        sort_des_seq = list_vip_sort_des_seq::type_id::create("sort_des_seq");
        sort_des_seq.start(env.get_sequencer());

        #500ns;

        // Read after sort (tb.sv line 469)
        read_seq = list_vip_read_seq::type_id::create("read_seq3");
        read_seq.num_reads = 5;
        read_seq.sequential = 1;
        read_seq.start(env.get_sequencer());

        #500ns;

        // Find first index (tb.sv line 472)
        find_1st_seq = list_vip_find_1st_seq::type_id::create("find_1st_seq");
        find_1st_seq.num_searches = 2;
        find_1st_seq.start(env.get_sequencer());

        #500ns;

        `uvm_info("DIRECT_OP_TEST", "Direct operation test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

//////////////////////////////////////////////////////////////////////////////////
// Random operation test
//////////////////////////////////////////////////////////////////////////////////

class random_test extends base_test;
    `uvm_component_utils(random_test)

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        list_vip_insert_seq insert_seq;
        list_vip_read_seq read_seq;
        list_vip_delete_seq delete_seq;
        list_vip_find_1st_seq find_seq;
        int op_sel;

        phase.raise_objection(this);

        `uvm_info("RANDOM_TEST", "Starting random operation test", UVM_LOW)

        // Initialize with some data
        insert_seq = list_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 4;
        insert_seq.start(env.get_sequencer());

        #200ns;

        // Random operations
        for (int i = 0; i < 15; i++) begin
            op_sel = $urandom_range(0, 3);

            case (op_sel)
                0: begin
                    insert_seq = list_vip_insert_seq::type_id::create($sformatf("insert_seq_%0d", i));
                    insert_seq.num_inserts = $urandom_range(1, 2);
                    insert_seq.start(env.get_sequencer());
                end
                1: begin
                    read_seq = list_vip_read_seq::type_id::create($sformatf("read_seq_%0d", i));
                    read_seq.num_reads = $urandom_range(1, 3);
                    read_seq.start(env.get_sequencer());
                end
                2: begin
                    delete_seq = list_vip_delete_seq::type_id::create($sformatf("delete_seq_%0d", i));
                    delete_seq.num_deletes = $urandom_range(1, 2);
                    delete_seq.start(env.get_sequencer());
                end
                3: begin
                    find_seq = list_vip_find_1st_seq::type_id::create($sformatf("find_seq_%0d", i));
                    find_seq.num_searches = 1;
                    find_seq.start(env.get_sequencer());
                end
            endcase

            #($urandom_range(100, 300));
        end

        #500ns;

        `uvm_info("RANDOM_TEST", "Random test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class list_vip_boundary_seq extends list_vip_base_seq;
    `uvm_object_utils(list_vip_boundary_seq)
    list_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(list_op_e op, int data, int index);
        list_vip_seq_item item = list_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = op; item.data = data; item.index = index;
        finish_item(item);
    endtask
    task reset_dut();
        virtual list_vip_if vif;
        if (!uvm_config_db#(virtual list_vip_if)::get(m_sequencer, "", "list_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(list_vip_config)::get(m_sequencer, "", "list_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        send(READ, 0, 0);
        send(DELETE, 0, 0);
        send(SUM, 0, 0);
        send(FIND_ALL, 0, 0);
        send(SORT_ASC, 0, 0);
        for (int i=0; i<cfg.LENGTH; i++) send(INSERT, (i%2) ? 255 : 7, cfg.LENGTH-1);
        send(INSERT, 42, 0);
        send(FIND_ALL, 7, 0);
        send(FIND_1ST, 255, 0);
        send(FIND_ALL, 8, 0);
        send(SUM, 0, 0);
        send(SORT_ASC, 0, 0);
        for (int i=0; i<cfg.LENGTH; i++) send(READ, 0, i);
        send(SORT_DES, 0, 0);
        for (int i=0; i<cfg.LENGTH; i++) send(READ, 0, i);
        send(DELETE, 0, 3);
        send(INSERT, 9, 2);
        reset_dut();
        send(SUM, 0, 0);
        send(INSERT, 77, 0);
        send(READ, 0, 0);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        list_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = list_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
