class ready_test extends reg_test;
  `uvm_component_utils(ready_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    bit [1:0]  r;
    phase.raise_objection(this);
    env.axil.drv.slow_ready = 1;

    reg_wr(8'h00, 1);
    reg_rd(8'h00, d);  chk("CTRL readback", d, 1);
    reg_wr(8'h0C, 1);
    reg_rd(8'h0C, d);  chk("IRQ_EN readback", d, 1);

    repeat (12) begin
      send_pkt($urandom_range(1, 40), ($urandom_range(0, 3) == 0));
      reg_rd(8'h04, d);
      reg_rd(8'h08, d);
    end

    wr_resp(8'h04, 1, r);  chk("write STATUS resp", r, 2);
    rd_resp(8'h30, d, r);  chk("read unmapped resp", r, 2);

    #100ns;
    `uvm_info("READY", $sformatf("%0d slow-ready checks", n_chk), UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass

class enable_test extends reg_test;
  `uvm_component_utils(enable_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    phase.raise_objection(this);

    fork
      send_pkt(9, 0);
      begin
        #600ns;
        chk("nothing accepted while disabled", env.sb.exp_q.size(), 0);
        reg_rd(8'h04, d);
        chk("STATUS empty while disabled", d[0], 1);
        reg_wr(8'h00, 1);
      end
    join

    #100ns;
    reg_rd(8'h04, d);
    chk("STATUS not empty after enable", d[0], 0);
    reg_rd(8'h08, d);

    #100ns;
    `uvm_info("ENABLE", $sformatf("%0d enable checks", n_chk), UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass