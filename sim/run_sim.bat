@echo off
call D:\2025.2\Vivado\settings64.bat
call xsc ..\dpi\ref_model.c
call xvlog -sv -L uvm -i ..\tb %3\sync_fifo.sv %3\pkt_rx.sv %3\axil_crc.sv ..\tb\axil_if.sv ..\tb\axis_if.sv ..\tb\tb_pkg.sv ..\tb\crc_sva.sv ..\tb\tb_top.sv
call xelab -L uvm tb_top -sv_lib dpi -s mut_snap -timescale 1ns/1ps
call xsim mut_snap -runall -sv_seed %2 -testplusarg "UVM_TESTNAME=%1"