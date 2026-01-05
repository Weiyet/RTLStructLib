//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_simple_test
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        dll_vip_insert_at_addr_seq insert_seq;
        dll_vip_read_seq read_seq;
        dll_vip_delete_at_addr_seq delete_seq;

        phase.raise_objection(this);
        `uvm_info("SIMPLE_TEST", "Starting simple doubly linked list test", UVM_LOW)

        insert_seq = dll_vip_insert_at_addr_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 5;
        insert_seq.start(env.get_sequencer());

        #500ns;

        read_seq = dll_vip_read_seq::type_id::create("read_seq");
        read_seq.num_reads = 5;
        read_seq.start(env.get_sequencer());

        #500ns;

        delete_seq = dll_vip_delete_at_addr_seq::type_id::create("delete_seq");
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
        dll_vip_insert_at_index_seq insert_seq;
        dll_vip_read_seq read_seq;
        dll_vip_delete_at_index_seq delete_seq;
        int op_sel;

        phase.raise_objection(this);
        `uvm_info("RANDOM_TEST", "Starting random test", UVM_LOW)

        insert_seq = dll_vip_insert_at_index_seq::type_id::create("init_insert");
        insert_seq.num_inserts = 4;
        insert_seq.start(env.get_sequencer());

        #300ns;

        for (int i = 0; i < 10; i++) begin
            op_sel = $urandom_range(0, 2);
            case (op_sel)
                0: begin
                    insert_seq = dll_vip_insert_at_index_seq::type_id::create($sformatf("insert_%0d", i));
                    insert_seq.num_inserts = $urandom_range(1, 2);
                    insert_seq.start(env.get_sequencer());
                end
                1: begin
                    read_seq = dll_vip_read_seq::type_id::create($sformatf("read_%0d", i));
                    read_seq.num_reads = $urandom_range(1, 3);
                    read_seq.start(env.get_sequencer());
                end
                2: begin
                    delete_seq = dll_vip_delete_at_index_seq::type_id::create($sformatf("delete_%0d", i));
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
