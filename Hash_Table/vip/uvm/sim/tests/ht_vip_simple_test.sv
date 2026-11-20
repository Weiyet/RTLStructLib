//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_simple_test
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        ht_vip_insert_seq insert_seq;
        ht_vip_search_seq search_seq;
        ht_vip_delete_seq delete_seq;

        phase.raise_objection(this);
        `uvm_info("SIMPLE_TEST", "Starting simple hash table test", UVM_LOW)

        insert_seq = ht_vip_insert_seq::type_id::create("insert_seq");
        insert_seq.num_inserts = 10;
        insert_seq.start(env.get_sequencer());

        #500ns;

        search_seq = ht_vip_search_seq::type_id::create("search_seq");
        search_seq.num_searches = 10;
        search_seq.start(env.get_sequencer());

        #500ns;

        delete_seq = ht_vip_delete_seq::type_id::create("delete_seq");
        delete_seq.num_deletes = 5;
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
        ht_vip_insert_seq insert_seq;
        ht_vip_search_seq search_seq;
        ht_vip_delete_seq delete_seq;
        int op_sel;

        phase.raise_objection(this);
        `uvm_info("RANDOM_TEST", "Starting random test", UVM_LOW)

        insert_seq = ht_vip_insert_seq::type_id::create("init_insert");
        insert_seq.num_inserts = 8;
        insert_seq.start(env.get_sequencer());

        #300ns;

        for (int i = 0; i < 15; i++) begin
            op_sel = $urandom_range(0, 2);
            case (op_sel)
                0: begin
                    insert_seq = ht_vip_insert_seq::type_id::create($sformatf("insert_%0d", i));
                    insert_seq.num_inserts = $urandom_range(1, 3);
                    insert_seq.start(env.get_sequencer());
                end
                1: begin
                    search_seq = ht_vip_search_seq::type_id::create($sformatf("search_%0d", i));
                    search_seq.num_searches = $urandom_range(2, 5);
                    search_seq.start(env.get_sequencer());
                end
                2: begin
                    delete_seq = ht_vip_delete_seq::type_id::create($sformatf("delete_%0d", i));
                    delete_seq.num_deletes = $urandom_range(1, 2);
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

class collision_test extends base_test;
    `uvm_component_utils(collision_test)

    function new(string name = "collision_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        ht_vip_insert_seq insert_seq;
        ht_vip_search_seq search_seq;

        phase.raise_objection(this);
        `uvm_info("COLLISION_TEST", "Starting collision stress test", UVM_LOW)

        // Insert many items to force collisions
        insert_seq = ht_vip_insert_seq::type_id::create("collision_insert");
        insert_seq.num_inserts = 30;
        insert_seq.start(env.get_sequencer());

        #1000ns;

        // Search for inserted items
        search_seq = ht_vip_search_seq::type_id::create("verify_search");
        search_seq.num_searches = 30;
        search_seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("COLLISION_TEST", "Collision test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class ht_vip_boundary_seq extends ht_vip_base_seq;
    `uvm_object_utils(ht_vip_boundary_seq)
    ht_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(ht_op_e op, bit [31:0] key, bit [31:0] value);
        ht_vip_seq_item item = ht_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = op; item.key = key; item.value = value;
        finish_item(item);
    endtask
    task reset_dut();
        virtual ht_vip_if vif;
        if (!uvm_config_db#(virtual ht_vip_if)::get(m_sequencer, "", "ht_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst = 1;
        repeat (3) @(negedge vif.clk);
        vif.rst = 0;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(ht_vip_config)::get(m_sequencer, "", "ht_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        send(SEARCH, 0, 0);
        for (int i=0; i<cfg.CHAINING_SIZE; i++) send(INSERT, i*cfg.TOTAL_INDEX, 100+i);
        send(INSERT, cfg.CHAINING_SIZE*cfg.TOTAL_INDEX, 999);
        send(INSERT, 0, 32'hffffffff);
        for (int i=0; i<cfg.CHAINING_SIZE; i++) send(SEARCH, i*cfg.TOTAL_INDEX, 0);
        send(DELETE, cfg.TOTAL_INDEX, 0);
        send(SEARCH, cfg.TOTAL_INDEX, 0);
        send(INSERT, cfg.CHAINING_SIZE*cfg.TOTAL_INDEX, 0);
        send(SEARCH, cfg.CHAINING_SIZE*cfg.TOTAL_INDEX, 0);
        send(INSERT, 1, 55);
        send(SEARCH, 1, 0);
        send(IDLE, 1, 0);
        send(DELETE, 32'hffffffff, 0);
        reset_dut();
        send(SEARCH, 1, 0);
        send(INSERT, 0, 0);
        send(SEARCH, 0, 0);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        ht_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = ht_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
