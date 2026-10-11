class fifo_test extends reg_test;
  `uvm_component_utils(fifo_test)

  bit ninth_done;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] d;
    int        guard;
    phase.raise_objection(this);
    reg_wr(8'h00, 1);

    fork
      begin
        for (int i = 0; i < 9; i++)
          send_pkt($urandom_range(1, 20), (i % 3 == 0));
        ninth_done = 1;
      end
      begin
        while (env.sb.exp_q.size() < 8 && guard++ < 500) #100ns;
        #300ns;
        reg_rd(8'h04, d);
        chk("STATUS full",         d[1], 1);
        chk("STATUS not empty",    d[0], 0);
        chk("packets accepted",    env.sb.exp_q.size(), 8);
        chk("ninth still blocked", ninth_done, 0);

        reg_rd(8'h08, d);
        #1us;
        chk("ninth released",      ninth_done, 1);

        repeat (8) reg_rd(8'h08, d);
        reg_rd(8'h04, d);
        chk("STATUS empty at end", d[0], 1);
        chk("STATUS full cleared", d[1], 0);
      end
    join

    #100ns;
    `uvm_info("FIFO", $sformatf("%0d fifo checks", n_chk), UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass