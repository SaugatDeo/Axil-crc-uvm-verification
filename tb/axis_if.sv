`timescale 1ns/1ps

interface axis_if (input logic clk, input logic rstn);
  logic [7:0] tdata;
  logic       tvalid, tlast, tready;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output tdata, tvalid, tlast;
    input  tready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input tdata, tvalid, tlast, tready;
  endclocking
endinterface