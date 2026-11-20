//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_simple_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Simple test demonstrating push and pop operations
//
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        lifo_vip_push_seq push_seq;
        lifo_vip_pop_seq pop_seq;

        phase.raise_objection(this);

        `uvm_info("SIMPLE_TEST", "Starting simple LIFO test", UVM_LOW)

        // Push some data
        push_seq = lifo_vip_push_seq::type_id::create("push_seq");
        push_seq.num_pushes = 8;
        push_seq.start(env.get_sequencer());

        #200ns;

        // Pop it back
        pop_seq = lifo_vip_pop_seq::type_id::create("pop_seq");
        pop_seq.num_pops = 8;
        pop_seq.start(env.get_sequencer());

        #200ns;

        `uvm_info("SIMPLE_TEST", "Simple test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

//////////////////////////////////////////////////////////////////////////////////
// Random operations test - similar to tb/sv/tb.sv behavior
//////////////////////////////////////////////////////////////////////////////////

class random_test extends base_test;
    `uvm_component_utils(random_test)

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        lifo_vip_push_seq push_seq;
        lifo_vip_pop_seq pop_seq;
        int op_sel;
        int num_ops;

        phase.raise_objection(this);

        `uvm_info("RANDOM_TEST", "Starting random LIFO test", UVM_LOW)

        // Random sequence of operations
        for (int i = 0; i < 20; i++) begin
            op_sel = $urandom_range(0, 1);
            num_ops = $urandom_range(1, 5);

            if (op_sel == 0) begin
                // Push operation
                push_seq = lifo_vip_push_seq::type_id::create("push_seq");
                push_seq.num_pushes = num_ops;
                push_seq.start(env.get_sequencer());
            end else begin
                // Pop operation
                pop_seq = lifo_vip_pop_seq::type_id::create("pop_seq");
                pop_seq.num_pops = num_ops;
                pop_seq.start(env.get_sequencer());
            end

            #100ns;
        end

        #500ns;

        `uvm_info("RANDOM_TEST", "Random test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

//////////////////////////////////////////////////////////////////////////////////
// Full/Empty test - tests boundary conditions
//////////////////////////////////////////////////////////////////////////////////

class full_empty_test extends base_test;
    `uvm_component_utils(full_empty_test)

    function new(string name = "full_empty_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        lifo_vip_push_seq push_seq;
        lifo_vip_pop_seq pop_seq;

        phase.raise_objection(this);

        `uvm_info("FULL_EMPTY_TEST", "Starting full/empty test", UVM_LOW)

        // Fill the LIFO completely
        push_seq = lifo_vip_push_seq::type_id::create("push_seq");
        push_seq.num_pushes = cfg.DEPTH + 3; // Try to overfill
        push_seq.start(env.get_sequencer());

        #500ns;

        // Empty the LIFO completely
        pop_seq = lifo_vip_pop_seq::type_id::create("pop_seq");
        pop_seq.num_pops = cfg.DEPTH + 3; // Try to over-empty
        pop_seq.start(env.get_sequencer());

        #500ns;

        `uvm_info("FULL_EMPTY_TEST", "Full/empty test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class lifo_vip_boundary_seq extends lifo_vip_base_seq;
    `uvm_object_utils(lifo_vip_boundary_seq)
    lifo_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(lifo_op_e op, int data=0, bit bypass=0);
        lifo_vip_seq_item item = lifo_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = op; item.data = data; item.bypass = bypass;
        finish_item(item);
    endtask
    task reset_dut();
        virtual lifo_vip_if vif;
        if (!uvm_config_db#(virtual lifo_vip_if)::get(m_sequencer, "", "lifo_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(lifo_vip_config)::get(m_sequencer, "", "lifo_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        send(POP);
        send(PUSH, 42, 1);
        repeat (2) begin
            for (int i=0; i<cfg.DEPTH; i++) send(PUSH, i+1);
            send(PUSH, 99);
            send(PUSH, 8'hff, 1);
            for (int i=0; i<cfg.DEPTH+1; i++) send(POP);
        end
        send(PUSH, 23);
        send(PUSH, 24);
        reset_dut();
        send(POP);
        send(PUSH, 8'ha5);
        send(POP);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        lifo_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = lifo_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
