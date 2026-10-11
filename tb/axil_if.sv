`timescale 1ns/1ps

interface axil_if (input logic clk, input logic rstn);
  logic [7:0]  awaddr;
  logic        awvalid, awready;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wvalid, wready;
  logic [1:0]  bresp;
  logic        bvalid, bready;
  logic [7:0]  araddr;
  logic        arvalid, arready;
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid, rready;
  logic        irq;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output awaddr, awvalid, wdata, wstrb, wvalid, bready,
           araddr, arvalid, rready;
    input  awready, wready, bresp, bvalid,
           arready, rdata, rresp, rvalid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input awaddr, awvalid, awready, wdata, wvalid, wready,
          bresp, bvalid, bready, araddr, arvalid, arready,
          rdata, rresp, rvalid, rready;
  endclocking
endinterface