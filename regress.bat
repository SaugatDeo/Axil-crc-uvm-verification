@echo off
if not exist logs mkdir logs

for /f %%T in (tests.txt) do (
  echo running %%T
  call run_cov.bat %%T 1 > logs\%%T_s1.log 2>&1
)

call merge_cov.bat > logs\merge.log 2>&1

for /f %%T in (tests.txt) do (
  echo ---- %%T
  findstr /C:"checks=" /C:"UVM_ERROR :" /C:"UVM_FATAL :" /C:"SVA FAIL" /C:"STREAM MISMATCH" /C:"no matching send" /C:"never seen" /C:"RACE hit" logs\%%T_s1.log
)
echo ---- merged
findstr /C:"Coverage Score" /C:"CCI-MERGE" logs\merge.log