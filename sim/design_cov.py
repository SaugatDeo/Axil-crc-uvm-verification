import re
import sys
from pathlib import Path

SIM = Path(__file__).resolve().parent
REP = sys.argv[1] if len(sys.argv) > 1 else "rep_merged"
PAGE = SIM / REP / "codeCoverageReport" / "modules.html"
OUT = SIM.parent / "doc" / f"design_coverage_{REP}.md"
WANT = ["axil_crc", "pkt_rx", "sync_fifo_default"]


def cells(row):
    found = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S | re.I)
    return [re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", c)).strip() for c in found]


def main():
    html = PAGE.read_text(errors="replace")
    got = {}
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S | re.I):
        c = cells(row)
        for name in WANT:
            if name in c:
                i = c.index(name)
                got[name] = c[i + 3:i + 7]

    lines = ["| Module | Statement | Branch | Condition | Toggle |",
             "|---|---|---|---|---|"]
    for name in WANT:
        vals = got.get(name)
        if not vals or len(vals) < 4:
            print(f"could not read {name}, cells found: {vals}")
            continue
        lines.append(f"| {name} | " + " | ".join(vals) + " |")
        print(f"{name:20s} stmt {vals[0]:>8}  branch {vals[1]:>8}  "
              f"cond {vals[2]:>8}  toggle {vals[3]:>8}")
    OUT.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()