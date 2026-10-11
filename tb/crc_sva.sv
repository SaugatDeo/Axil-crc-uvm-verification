module crc_sva (
  input logic        clk, rstn,
  input logic        awvalid, awready, wvalid, wready, bvalid, bready,
  input logic        arvalid, arready, rvalid, rready,
  input logic [7:0]  awaddr, araddr,
  input logic [31:0] rdata,
  input logic [1:0]  bresp, rresp,
  input logic        tvalid, tready, tlast,
  input logic [7:0]  tdata,
  input logic        enable, irq_en, irq_stat, crc_err_seen, clr,
  input logic        rx_push, fifo_pop, fifo_empty, fifo_full, irq_w1c, irq
);
  a_aw_hold: assert property (@(posedge clk) disable iff (!rstn)
    (awvalid && !awready) |=> (awvalid && $stable(awaddr)))
    else $error("SVA FAIL aw_hold");

  a_ar_hold: assert property (@(posedge clk) disable iff (!rstn)
    (arvalid && !arready) |=> (arvalid && $stable(araddr)))
    else $error("SVA FAIL ar_hold");

  a_b_hold: assert property (@(posedge clk) disable iff (!rstn)
    (bvalid && !bready) |=> (bvalid && $stable(bresp)))
    else $error("SVA FAIL b_hold");

  a_r_hold: assert property (@(posedge clk) disable iff (!rstn)
    (rvalid && !rready) |=> (rvalid && $stable(rdata) && $stable(rresp)))
    else $error("SVA FAIL r_hold");

  a_b_cause: assert property (@(posedge clk) disable iff (!rstn)
    $rose(bvalid) |-> $past(awvalid && wvalid))
    else $error("SVA FAIL b_without_write");

  a_r_cause: assert property (@(posedge clk) disable iff (!rstn)
    $rose(rvalid) |-> $past(arvalid))
    else $error("SVA FAIL r_without_read");

  a_axis_hold: assert property (@(posedge clk) disable iff (!rstn)
    (tvalid && !tready) |=> (tvalid && $stable(tdata) && $stable(tlast)))
    else $error("SVA FAIL axis_hold");

  a_full_stall: assert property (@(posedge clk) disable iff (!rstn)
    fifo_full |-> !tready)
    else $error("SVA FAIL ready_while_full");

  a_off_stall: assert property (@(posedge clk) disable iff (!rstn)
    !enable |-> !tready)
    else $error("SVA FAIL ready_while_disabled");

  a_underflow: assert property (@(posedge clk) disable iff (!rstn)
    fifo_pop |-> !fifo_empty)
    else $error("SVA FAIL pop_when_empty");

  a_overflow: assert property (@(posedge clk) disable iff (!rstn)
    rx_push |-> !fifo_full)
    else $error("SVA FAIL push_when_full");

  a_irq: assert property (@(posedge clk) disable iff (!rstn)
    irq == (irq_stat && irq_en))
    else $error("SVA FAIL irq_equation");

  a_soft: assert property (@(posedge clk) disable iff (!rstn)
    clr |=> (fifo_empty && !irq_stat && !crc_err_seen))
    else $error("SVA FAIL soft_reset_not_clean");

  a_race: assert property (@(posedge clk) disable iff (!rstn)
    (rx_push && irq_w1c) |=> irq_stat)
    else $error("SVA FAIL push_lost_to_clear");

  a_reset: assert property (@(posedge clk)
    !rstn |=> (!enable && !irq_en && fifo_empty && !irq_stat))
    else $error("SVA FAIL reset_values");

  always @(posedge clk)
    if (rstn && rx_push && irq_w1c) $display("RACE hit t=%0t", $time);

  covergroup cg_dut @(posedge clk);
    cp_full: coverpoint fifo_full {
      bins seen = {1};
    }
    cp_race: coverpoint (rx_push && irq_w1c) {
      bins push_and_clear_same_cycle = {1};
    }
    cp_soft: coverpoint clr {
      bins soft_reset = {1};
    }
  endgroup
  cg_dut cg = new();
endmodule