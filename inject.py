import re
import shutil
import subprocess
import sys
from pathlib import Path

SIM = Path(__file__).resolve().parent
RTL = SIM.parent / "rtl"
MUT = SIM / "mut"
DOC = SIM.parent / "doc"
LOGS = SIM / "logs"
TESTS = (SIM / "tests.txt").read_text().split()
SEED = 1
TIMEOUT = 300
STRAYS = ["xsim.exe", "xsimk.exe", "xelab.exe", "xvlog.exe", "xsc.exe"]

BUGS = [
    (1, "CRC residue constant wrong", "pkt_rx.sv",
     "32'hDEBB20E3;", "32'hDEBB20E2;"),
    (2, "Max length off by one, accepts 65 bytes", "pkt_rx.sv",
     "localparam int MAX_BYTES = 64;", "localparam int MAX_BYTES = 65;"),
    (3, "FIFO reports full one entry early", "sync_fifo.sv",
     "assign full = (cnt == DEPTH);", "assign full = (cnt == DEPTH - 1);"),
    (4, "tready ignores enable", "pkt_rx.sv",
     "assign tready = en && !fifo_full;", "assign tready = !fifo_full;"),
    (5, "crc_err_seen never set", "axil_crc.sv",
     "crc_err_seen <= 1'b1;", "crc_err_seen <= 1'b0;"),
    (6, "RESULT read does not pop the FIFO", "axil_crc.sv",
     "assign fifo_pop = rd_go && rd_pop;", "assign fifo_pop = 1'b0;"),
    (7, "Soft reset leaves irq_stat set", "axil_crc.sv",
     "crc_err_seen <= 1'b0; irq_stat <= 1'b0;",
     "crc_err_seen <= 1'b0; if (!rstn) irq_stat <= 1'b0;"),
    (8, "Write to read-only register returns OKAY", "axil_crc.sv",
     "s_axil_bresp <= SLVERR;", "s_axil_bresp <= OKAY;"),
    (9, "IRQ clear beats a push in the same cycle", "axil_crc.sv",
     "if (rx_push) irq_stat <= 1'b1; else if (irq_w1c) irq_stat <= 1'b0;",
     "if (irq_w1c) irq_stat <= 1'b0; else if (rx_push) irq_stat <= 1'b1;"),
]


def kill_strays():
    for name in STRAYS:
        subprocess.run(["taskkill", "/F", "/IM", name], capture_output=True)


def run(test, rtl_rel, tag):
    kill_strays()
    p = subprocess.Popen(
        ["cmd", "/c", "run_sim.bat", test, str(SEED), rtl_rel],
        cwd=SIM, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace")
    timed_out = False
    try:
        out, _ = p.communicate(timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(p.pid)],
                       capture_output=True)
        kill_strays()
        out, _ = p.communicate()
        timed_out = True
    LOGS.mkdir(exist_ok=True)
    (LOGS / f"inj_{tag}_{test}.log").write_text(out or "", errors="replace")
    if timed_out:
        return "hang"
    err = re.search(r"^ERROR: .*$", out, re.M)
    if err:
        print(f"    [{tag} {test}] {err.group(0)[:150]}")
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


def mutate(n, fname, old, new):
    dst = MUT / f"b{n:02d}"
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(RTL, dst)
    path = dst / fname
    text = path.read_text()
    pat = r"\s+".join(re.escape(t) for t in old.split())
    if len(re.findall(pat, text)) != 1:
        return None
    path.write_text(re.sub(pat, lambda m: new, text, count=1))
    return f"mut\\b{n:02d}"


def verdict(res):
    if "broken" in res:
        return "invalid"
    if all(r == "clean" for r in res):
        return "SURVIVED"
    return "caught"


def main():
    print("baseline")
    base = [run(t, r"..\rtl", "base") for t in TESTS]
    print("  ", dict(zip(TESTS, base)))
    if any(b != "clean" for b in base):
        sys.exit("baseline is not clean, fix that first")

    rows = []
    for n, name, fname, old, new in BUGS:
        rel = mutate(n, fname, old, new)
        if rel is None:
            rows.append((n, name, ["-"] * len(TESTS), "pattern not found"))
            print(f"bug {n}: pattern not found in {fname}")
            continue
        res = [run(t, rel, f"b{n:02d}") for t in TESTS]
        rows.append((n, name, res, verdict(res)))
        print(f"bug {n}: {res} -> {verdict(res)}")

    ok = [r for r in rows if r[3] in ("caught", "SURVIVED")]
    hit = sum(1 for r in ok if r[3] == "caught")
    lines = [
        f"# Bug injection (seed {SEED})", "",
        "| # | Injected bug | " + " | ".join(TESTS) + " | Result |",
        "|---|---|" + "---|" * len(TESTS) + "---|",
    ]
    for n, name, res, v in rows:
        lines.append(f"| {n} | {name} | " + " | ".join(res) + f" | {v} |")
    lines += ["", f"Caught {hit} of {len(ok)} valid bugs."]
    DOC.mkdir(exist_ok=True)
    (DOC / "bug_table.md").write_text("\n".join(lines) + "\n")
    print(f"\ncaught {hit} of {len(ok)} valid bugs, table in doc\\bug_table.md")


if __name__ == "__main__":
    main()