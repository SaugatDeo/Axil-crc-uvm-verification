class rand_test extends base_test;
  `uvm_component_utils(rand_test)

  int n_bursts = 20;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task send_random_pkt();
    int unsigned plen;
    bit          bad;
    void'(std::randomize(plen, bad) with {
      plen dist { 0 := 1, 1 := 3, [2:58] :/ 10, 59 := 1, 60 := 3, 61 := 1, [62:80] :/ 1 };
      bad  dist { 0 := 7, 1 := 3 };
    });
    send_pkt(plen, bad);
  endtask

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    int        burst;
    phase.raise_objection(this);
    reg_wr(8'h00, 32'h1);
    repeat (n_bursts) begin
      burst = $urandom_range(1, 8);
      repeat (burst) send_random_pkt();
      reg_rd(8'h04, d);
      repeat (burst) reg_rd(8'h08, d);
      if ($urandom_range(3) == 0) reg_rd(8'h08, d);
    end
    #100ns;
    phase.drop_objection(this);
  endtask
endclass