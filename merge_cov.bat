@echo off
call D:\2025.2\Vivado\settings64.bat
set ARGS=
for /f %%T in (tests.txt) do call set "ARGS=%%ARGS%% -cov_db_dir cov -cov_db_name %%T_s1"
call xcrg %ARGS% -merge_dir cov_merged -merge_db_name all -report_dir rep_merged