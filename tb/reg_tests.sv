class reg_test extends base_test;
  `uvm_component_utils(reg_test)

  virtual axil_if vif;
  int n_chk;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axil_if not set for reg_test")
  endfunction

  function void chk(string what, bit [31:0] got, bit [31:0] exp);
    n_chk++;
    if (got !== exp)
      `uvm_error("REG", $sformatf("%s: got %h exp %h", what, got, exp))
  endfunction

  task wr_resp(bit [7:0] a, bit [31:0] d, output bit [1:0] r);
    axil_reg_seq s = axil_reg_seq::type_id::create("s");
    s.s_kind = AXIL_WR;
    s.s_addr = a;
    s.s_data = d;
    s.start(env.axil.sqr);
    r = s.resp;
  endtask

  task rd_resp(bit [7:0] a, output bit [31:0] d, output bit [1:0] r);
    axil_reg_seq s = axil_reg_seq::type_id::create("s");
    s.s_kind = AXIL_RD;
    s.s_addr = a;
    s.start(env.axil.sqr);
    d = s.rdata;
    r = s.resp;
  endtask

  task irq_is(string what, bit exp);
    @(negedge vif.clk);
    chk(what, vif.irq, exp);
  endtask

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    bit [1:0]  r;
    phase.raise_objection(this);

    reg_rd(8'h00, d);  chk("CTRL reset", d, 0);
    reg_rd(8'h0C, d);  chk("IRQ_EN reset", d, 0);
    reg_rd(8'h10, d);  chk("IRQ_STAT reset", d, 0);
    reg_rd(8'h04, d);  chk("STATUS reset", d, 1);
    reg_rd(8'h08, d);  chk("RESULT empty", d, 0);

    reg_wr(8'h00, 1);  reg_rd(8'h00, d);  chk("CTRL readback", d, 1);
    reg_wr(8'h0C, 1);  reg_rd(8'h0C, d);  chk("IRQ_EN readback", d, 1);
    irq_is("irq idle", 0);

    send_pkt(9, 0);
    #50ns;
    reg_rd(8'h10, d);  chk("IRQ_STAT set", d, 1);
    irq_is("irq high", 1);
    reg_wr(8'h0C, 0);  irq_is("irq masked", 0);
    reg_wr(8'h0C, 1);  irq_is("irq unmasked", 1);
    reg_wr(8'h10, 1);  reg_rd(8'h10, d);  chk("IRQ_STAT w1c", d, 0);
    irq_is("irq cleared", 0);
    reg_rd(8'h08, d);

    send_pkt(9, 1);
    send_pkt(9, 0);
    #50ns;
    reg_rd(8'h04, d);  chk("crc_err seen", d[2], 1);
    reg_wr(8'h00, 3);
    #50ns;
    env.sb.exp_q.delete();
    reg_rd(8'h04, d);  chk("STATUS after soft reset", d, 1);
    reg_rd(8'h10, d);  chk("IRQ_STAT after soft reset", d, 0);

    wr_resp(8'h00, 1, r);     chk("write CTRL resp", r, 0);
    wr_resp(8'h04, 1, r);     chk("write STATUS resp", r, 2);
    wr_resp(8'h08, 1, r);     chk("write RESULT resp", r, 2);
    wr_resp(8'h20, 1, r);     chk("write unmapped resp", r, 2);
    rd_resp(8'h30, d, r);     chk("read unmapped resp", r, 2);
                              chk("read unmapped data", d, 0);

    #100ns;
    `uvm_info("REG", $sformatf("%0d register checks", n_chk), UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass