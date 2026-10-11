class long_test extends base_test;
  `uvm_component_utils(long_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0]   d;
    int unsigned lens[] = '{59, 60, 61, 127, 128, 131, 132, 200, 252, 253, 260};
    phase.raise_objection(this);
    reg_wr(8'h00, 1);
    foreach (lens[i]) begin
      send_pkt(lens[i], 0);
      reg_rd(8'h08, d);
    end
    #100ns;
    phase.drop_objection(this);
  endtask
endclass