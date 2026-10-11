class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  crc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_top.set_timeout(300us, 1);
    env = crc_env::type_id::create("env", this);
  endfunction

  task reg_wr(bit [7:0] a, bit [31:0] d);
    axil_reg_seq s = axil_reg_seq::type_id::create("s");
    s.s_kind = AXIL_WR;
    s.s_addr = a;
    s.s_data = d;
    s.start(env.axil.sqr);
  endtask

  task reg_rd(bit [7:0] a, output bit [31:0] d);
    axil_reg_seq s = axil_reg_seq::type_id::create("s");
    s.s_kind = AXIL_RD;
    s.s_addr = a;
    s.start(env.axil.sqr);
    d = s.rdata;
  endtask

  task send_pkt(int unsigned plen, bit corrupt);
    axis_pkt_seq s = axis_pkt_seq::type_id::create("s");
    s.s_plen    = plen;
    s.s_corrupt = corrupt;
    s.start(env.axis.sqr);
  endtask
endclass

class smoke_uvm_test extends base_test;
  `uvm_component_utils(smoke_uvm_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    phase.raise_objection(this);

    reg_wr(8'h00, 32'h1);
    send_pkt(9, 0);
    send_pkt(9, 1);
    #100ns;

    reg_rd(8'h04, d);
    `uvm_info("TEST", $sformatf("STATUS = %08h", d), UVM_LOW)
    reg_rd(8'h08, d);
    reg_rd(8'h08, d);

    #50ns;
    phase.drop_objection(this);
  endtask
endclass