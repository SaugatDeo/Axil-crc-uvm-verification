import re
import subprocess
import sys
from pathlib import Path

SIM = Path(__file__).resolve().parent
LOGS = SIM / "logs"
TESTS = (SIM / "tests.txt").read_text().split()
N = int(sys.argv[1]) if len(sys.argv) > 1 else 10
SEEDS = range(1, N + 1)
TIMEOUT = 600
STRAYS = ["xsim.exe", "xsimk.exe", "xelab.exe", "xvlog.exe", "xsc.exe"]


def kill_strays():
    for name in STRAYS:
        subprocess.run(["taskkill", "/F", "/IM", name], capture_output=True)


def classify(out):
    if re.search(r"^ERROR: \[", out, re.M):
        return "broken"
    m = re.search(r"UVM_ERROR :\s+(\d+)", out)
    if not m:
        return "no report"
    f = re.search(r"UVM_FATAL :\s+(\d+)", out)
    uvm = int(m.group(1)) + (int(f.group(1)) if f else 0)
    sva = "SVA FAIL" in out
    if sva and uvm:
        return "sva+uvm"
    if sva:
        return "sva"
    if uvm:
        return "uvm"
    return "clean"


def run_once(test, seed):
    kill_strays()
    try:
        p = subprocess.run(["cmd", "/c", "run_cov.bat", test, str(seed)],
                           cwd=SIM, capture_output=True, text=True,
                           errors="replace", timeout=TIMEOUT)
        out = p.stdout + p.stderr
        return classify(out), out
    except subprocess.TimeoutExpired:
        kill_strays()
        return "hang", ""


def main():
    LOGS.mkdir(exist_ok=True)
    bad, retried, done = [], [], []
    for t in TESTS:
        row = []
        for s in SEEDS:
            status, out = run_once(t, s)
            second = False
            if status == "broken":
                (LOGS / f"ms_{t}_s{s}_first.log").write_text(out, errors="replace")
                retried.append((t, s))
                status, out = run_once(t, s)
                second = True
            log = LOGS / f"ms_{t}_s{s}.log"
            log.write_text(out, errors="replace")
            if status == "clean":
                done.append(f"{t}_s{s}")
                row.append("r" if second else ".")
            else:
                bad.append((t, s, status, log))
                row.append(status)
        print(f"{t:12s} " + " ".join(row))

    print(f"\n{len(done)} clean runs, {len(bad)} not clean")
    for t, s, status, log in bad:
        print(f"  {t} seed {s}: {status}  ->  {log}")
    if retried:
        print("retried once after a build error (first log kept as *_first.log):")
        for t, s in retried:
            print(f"  {t} seed {s}")

    names = " ".join(f"-cov_db_dir cov -cov_db_name {d}" for d in done)
    bat = SIM / "merge_all.bat"
    bat.write_text("@echo off\n"
                   "call D:\\2025.2\\Vivado\\settings64.bat\n"
                   f"call xcrg {names} -merge_dir cov_merged_all "
                   "-merge_db_name all -report_dir rep_merged_all\n")
    p = subprocess.run(["cmd", "/c", "merge_all.bat"], cwd=SIM,
                       capture_output=True, text=True, errors="replace")
    (LOGS / "merge_all.log").write_text(p.stdout + p.stderr, errors="replace")
    for line in (p.stdout + p.stderr).splitlines():
        if "Coverage Score" in line or "CCI-MERGE" in line:
            print(line.strip())
    subprocess.run([sys.executable, "design_cov.py", "rep_merged_all"], cwd=SIM)


if __name__ == "__main__":
    main()