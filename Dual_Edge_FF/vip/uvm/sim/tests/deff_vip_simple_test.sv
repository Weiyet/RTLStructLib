//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_simple_test
//////////////////////////////////////////////////////////////////////////////////

class simple_test extends base_test;
    `uvm_component_utils(simple_test)

    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_random_seq seq;

        phase.raise_objection(this);
        `uvm_info("SIMPLE_TEST", "Starting simple dual edge FF test", UVM_LOW)

        seq = deff_vip_random_seq::type_id::create("seq");
        seq.num_items = 50;
        seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("SIMPLE_TEST", "Simple test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class pos_edge_test extends base_test;
    `uvm_component_utils(pos_edge_test)

    function new(string name = "pos_edge_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_pos_edge_only_seq seq;

        phase.raise_objection(this);
        `uvm_info("POS_EDGE_TEST", "Starting positive edge only test", UVM_LOW)

        seq = deff_vip_pos_edge_only_seq::type_id::create("seq");
        seq.num_items = 30;
        seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("POS_EDGE_TEST", "Positive edge test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class neg_edge_test extends base_test;
    `uvm_component_utils(neg_edge_test)

    function new(string name = "neg_edge_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_neg_edge_only_seq seq;

        phase.raise_objection(this);
        `uvm_info("NEG_EDGE_TEST", "Starting negative edge only test", UVM_LOW)

        seq = deff_vip_neg_edge_only_seq::type_id::create("seq");
        seq.num_items = 30;
        seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("NEG_EDGE_TEST", "Negative edge test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class dual_edge_test extends base_test;
    `uvm_component_utils(dual_edge_test)

    function new(string name = "dual_edge_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_dual_edge_seq seq;

        phase.raise_objection(this);
        `uvm_info("DUAL_EDGE_TEST", "Starting dual edge test (both edges active)", UVM_LOW)

        seq = deff_vip_dual_edge_seq::type_id::create("seq");
        seq.num_items = 30;
        seq.start(env.get_sequencer());

        #500ns;
        `uvm_info("DUAL_EDGE_TEST", "Dual edge test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class random_test extends base_test;
    `uvm_component_utils(random_test)

    function new(string name = "random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        deff_vip_pos_edge_only_seq pos_seq;
        deff_vip_neg_edge_only_seq neg_seq;
        deff_vip_dual_edge_seq dual_seq;
        int seq_sel;

        phase.raise_objection(this);
        `uvm_info("RANDOM_TEST", "Starting random test", UVM_LOW)

        for (int i = 0; i < 10; i++) begin
            seq_sel = $urandom_range(0, 2);
            case (seq_sel)
                0: begin
                    pos_seq = deff_vip_pos_edge_only_seq::type_id::create($sformatf("pos_%0d", i));
                    pos_seq.num_items = $urandom_range(5, 15);
                    pos_seq.start(env.get_sequencer());
                end
                1: begin
                    neg_seq = deff_vip_neg_edge_only_seq::type_id::create($sformatf("neg_%0d", i));
                    neg_seq.num_items = $urandom_range(5, 15);
                    neg_seq.start(env.get_sequencer());
                end
                2: begin
                    dual_seq = deff_vip_dual_edge_seq::type_id::create($sformatf("dual_%0d", i));
                    dual_seq.num_items = $urandom_range(5, 15);
                    dual_seq.start(env.get_sequencer());
                end
            endcase
            #($urandom_range(100, 300));
        end

        #500ns;
        `uvm_info("RANDOM_TEST", "Random test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

class deff_vip_boundary_seq extends deff_vip_base_seq;
    `uvm_object_utils(deff_vip_boundary_seq)
    deff_vip_config cfg;
    function new(string name = "boundary_seq"); super.new(name); endfunction
    task send(bit [7:0] data, bit [7:0] pos_en, bit [7:0] neg_en);
        deff_vip_seq_item item = deff_vip_seq_item::type_id::create("item");
        start_item(item);
        item.data_in = data; item.pos_edge_latch_en = pos_en; item.neg_edge_latch_en = neg_en;
        finish_item(item);
    endtask
    task reset_dut();
        virtual deff_vip_if vif;
        if (!uvm_config_db#(virtual deff_vip_if)::get(m_sequencer, "", "deff_vip_vif", vif))
            `uvm_fatal("CONFIG", "Missing interface")
        @(negedge vif.clk);
        vif.rst_n = 0;
        repeat (3) @(negedge vif.clk);
        vif.rst_n = 1;
        repeat (2) @(negedge vif.clk);
    endtask
    task body();
        if (!uvm_config_db#(deff_vip_config)::get(m_sequencer, "", "deff_vip_cfg", cfg))
            `uvm_fatal("CONFIG", "Missing config")
        send(8'hff, 0, 0);
        for (int i=0; i<8; i++) begin
            send(8'hff, 1<<i, 0);
            send(0, 0, 1<<i);
        end
        send(8'haa, 8'h55, 8'haa);
        send(8'h55, 8'haa, 8'h55);
        send(8'hff, 8'hff, 8'hff);
        reset_dut();
        send(0, 0, 0);
        send(8'ha5, 8'hff, 8'hff);
    endtask
endclass

class boundary_test extends base_test;
    `uvm_component_utils(boundary_test)
    function new(string name = "boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        deff_vip_boundary_seq seq;
        phase.raise_objection(this);
        seq = deff_vip_boundary_seq::type_id::create("boundary");
        seq.start(env.get_sequencer());
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
