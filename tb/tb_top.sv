`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import tb_pkg::*;

  logic clk = 0, rstn = 0;
  always #5 clk = ~clk;
  initial #42 rstn = 1;

  axil_if axil_vif (clk, rstn);
  axis_if axis_vif (clk, rstn);

  axil_crc dut (
    .clk, .rstn,
    .s_axil_awaddr (axil_vif.awaddr),  .s_axil_awvalid(axil_vif.awvalid),
    .s_axil_awready(axil_vif.awready),
    .s_axil_wdata  (axil_vif.wdata),   .s_axil_wstrb  (axil_vif.wstrb),
    .s_axil_wvalid (axil_vif.wvalid),  .s_axil_wready (axil_vif.wready),
    .s_axil_bresp  (axil_vif.bresp),   .s_axil_bvalid (axil_vif.bvalid),
    .s_axil_bready (axil_vif.bready),
    .s_axil_araddr (axil_vif.araddr),  .s_axil_arvalid(axil_vif.arvalid),
    .s_axil_arready(axil_vif.arready),
    .s_axil_rdata  (axil_vif.rdata),   .s_axil_rresp  (axil_vif.rresp),
    .s_axil_rvalid (axil_vif.rvalid),  .s_axil_rready (axil_vif.rready),
    .s_axis_tdata  (axis_vif.tdata),   .s_axis_tvalid (axis_vif.tvalid),
    .s_axis_tlast  (axis_vif.tlast),   .s_axis_tready (axis_vif.tready),
    .irq           (axil_vif.irq)
  );

  crc_sva u_sva (
    .clk, .rstn,
    .awvalid(axil_vif.awvalid), .awready(axil_vif.awready),
    .wvalid (axil_vif.wvalid),  .wready (axil_vif.wready),
    .bvalid (axil_vif.bvalid),  .bready (axil_vif.bready),
    .arvalid(axil_vif.arvalid), .arready(axil_vif.arready),
    .rvalid (axil_vif.rvalid),  .rready (axil_vif.rready),
    .awaddr (axil_vif.awaddr),  .araddr (axil_vif.araddr),
    .rdata  (axil_vif.rdata),
    .bresp  (axil_vif.bresp),   .rresp  (axil_vif.rresp),
    .tvalid (axis_vif.tvalid),  .tready (axis_vif.tready),
    .tlast  (axis_vif.tlast),   .tdata  (axis_vif.tdata),
    .enable      (dut.enable),       .irq_en   (dut.irq_en),
    .irq_stat    (dut.irq_stat),     .crc_err_seen(dut.crc_err_seen),
    .clr         (dut.clr),          .rx_push  (dut.rx_push),
    .fifo_pop    (dut.fifo_pop),     .fifo_empty(dut.fifo_empty),
    .fifo_full   (dut.fifo_full),    .irq_w1c  (dut.irq_w1c),
    .irq         (axil_vif.irq)
  );

  initial begin
    uvm_config_db#(virtual axil_if)::set(null, "uvm_test_top.env.axil*", "vif", axil_vif);
    uvm_config_db#(virtual axis_if)::set(null, "uvm_test_top.env.axis*", "vif", axis_vif);
    uvm_config_db#(virtual axil_if)::set(null, "uvm_test_top", "vif", axil_vif);
    run_test();
  end
endmodule