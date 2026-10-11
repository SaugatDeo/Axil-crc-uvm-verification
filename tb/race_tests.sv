class axis_nogap_seq extends uvm_sequence #(axis_item);
  `uvm_object_utils(axis_nogap_seq)

  function new(string name = "axis_nogap_seq");
    super.new(name);
  endfunction

  task body();
    axis_item t = axis_item::type_id::create("t");
    start_item(t);
    if (!t.randomize() with { plen == 9; corrupt == 0; foreach (gap[i]) gap[i] == 0; })
      `uvm_fatal("RAND", "axis_item randomize failed")
    finish_item(t);
  endtask
endclass

class axil_w1c_seq extends uvm_sequence #(axil_item);
  `uvm_object_utils(axil_w1c_seq)

  function new(string name = "axil_w1c_seq");
    super.new(name);
  endfunction

  task body();
    axil_item t = axil_item::type_id::create("t");
    start_item(t);
    if (!t.randomize() with { kind == AXIL_WR; addr == 8'h10; data == 32'h1; delay == 0; })
      `uvm_fatal("RAND", "axil_item randomize failed")
    finish_item(t);
  endtask
endclass

class race_test extends reg_test;
  `uvm_component_utils(race_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task one_round(int k);
    bit [31:0] d;
    fork
      begin
        axis_nogap_seq p = axis_nogap_seq::type_id::create("p");
        p.start(env.axis.sqr);
      end
      begin
        axil_w1c_seq w = axil_w1c_seq::type_id::create("w");
        repeat (k) @(posedge vif.clk);
        w.start(env.axil.sqr);
      end
    join
    reg_rd(8'h10, d);
    reg_rd(8'h08, d);
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    reg_wr(8'h00, 1);
    reg_wr(8'h0C, 1);
    for (int k = 0; k < 40; k++) one_round(k);
    #100ns;
    `uvm_info("RACE", "40 offset rounds done", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass