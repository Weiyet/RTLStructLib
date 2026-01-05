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
