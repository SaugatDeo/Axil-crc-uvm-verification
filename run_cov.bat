call D:\2025.2\Vivado\settings64.bat
set TEST=%1
if "%TEST%"=="" set TEST=smoke_uvm_test
set SEED=%2
if "%SEED%"=="" set SEED=1
set DB=%TEST%_s%SEED%
call xsc ..\dpi\ref_model.c
call xvlog -sv -L uvm -i ..\tb ..\rtl\sync_fifo.sv ..\rtl\pkt_rx.sv ..\rtl\axil_crc.sv ..\tb\axil_if.sv ..\tb\axis_if.sv ..\tb\tb_pkg.sv ..\tb\crc_sva.sv ..\tb\tb_top.sv
call xelab -L uvm tb_top -sv_lib dpi -s cov_snap -timescale 1ns/1ps -cc_type sbct -cov_db_name %DB% -cov_db_dir cov
call xsim cov_snap -runall -sv_seed %SEED% -testplusarg "UVM_TESTNAME=%TEST%"
call xcrg -report_dir rep_%DB% -cov_db_dir cov -cov_db_name %DB%