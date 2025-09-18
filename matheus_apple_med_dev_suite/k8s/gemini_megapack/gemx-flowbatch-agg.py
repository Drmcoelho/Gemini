#!/usr/bin/env python3
"""
gemx-flowbatch-agg.py — agrega múltiplos flowbatch-*.jsonl em um sumário CSV/HTML.

- Entrada: ~/.config/gemx/logs/flowbatch-YYYYMMDD.jsonl (ou --glob personalizado)
- Saída: --out-dir (default ./flowbatch_report) contendo:
    - CSVs: events.csv, flows.csv, daily.csv
    - HTML: index.html + PNGs em report_assets/

Gráficos via matplotlib (um gráfico por figura, sem cores explícitas).
"""
import os, sys, json, argparse, glob, datetime
from collections import Counter, defaultdict

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--logdir", type=str, default=os.path.expanduser("~/.config/gemx/logs"))
    ap.add_argument("--glob", type=str, default="flowbatch-*.jsonl")
    ap.add_argument("--out-dir", type=str, default="./flowbatch_report")
    return ap.parse_args()

def iter_files(logdir, pattern):
    for path in sorted(glob.glob(os.path.join(logdir, pattern))):
        yield path

def iter_rows(paths):
    for p in paths:
        with open(p, "r", encoding="utf-8") as fh:
            for line in fh:
                line=line.strip()
                if not line: continue
                try:
                    obj=json.loads(line)
                except Exception:
                    continue
                # expected keys: ts,event,flow,status,attempt,duration,msg
                yield obj

def ensure_dir(p):
    os.makedirs(p, exist_ok=True)

def save_csv(path, header, rows):
    with open(path, "w", encoding="utf-8") as f:
        f.write(",".join(header) + "\n")
        for r in rows:
            f.write(",".join(str(x) for x in r) + "\n")

def save_bar(figpath, labels, values, title, xlabel, ylabel):
    import matplotlib.pyplot as plt
    plt.figure()
    plt.bar(range(len(values)), values)
    plt.xticks(range(len(labels)), labels, rotation=45, ha='right')
    plt.title(title)
    plt.xlabel(xlabel); plt.ylabel(ylabel)
    plt.tight_layout()
    plt.savefig(figpath)
    plt.close()

def save_line(figpath, xs, ys, title, xlabel, ylabel):
    import matplotlib.pyplot as plt
    plt.figure()
    plt.plot(xs, ys)
    plt.title(title)
    plt.xlabel(xlabel); plt.ylabel(ylabel)
    plt.tight_layout()
    plt.savefig(figpath)
    plt.close()

def main():
    args = parse_args()
    ensure_dir(args.out_dir)
    assets = os.path.join(args.out_dir, "report_assets")
    ensure_dir(assets)

    events = Counter()
    flows_runs = Counter()       # by flow, finishes
    flows_fail = Counter()       # by flow, fails
    dur_sum = Counter()
    dur_n = Counter()
    daily = Counter()

    for obj in iter_rows(iter_files(args.logdir, args.glob)):
        ev = obj.get("event")
        events[ev]+=1
        fl = obj.get("flow","(unknown)")
        if ev == "finish":
            flows_runs[fl]+=1
            d = int(obj.get("duration",0) or 0)
            dur_sum[fl]+=d
            dur_n[fl]+=1
            ts = obj.get("ts")
            try:
                dt = datetime.datetime.fromisoformat(ts.replace("Z","+00:00"))
                daily[dt.date()]+=1
            except Exception:
                pass
        elif ev in ("error","fail"):
            flows_fail[fl]+=1

    # CSVs
    save_csv(os.path.join(args.out_dir, "events.csv"),
             ["event","count"], sorted(events.items(), key=lambda x:x[0]))

    # flows.csv: flow, finishes, fails, success_rate, avg_duration
    rows=[]
    for fl in set(list(flows_runs.keys()) + list(flows_fail.keys())):
        fin=flows_runs[fl]
        fai=flows_fail[fl]
        tot=fin+fai
        sr= (fin/float(tot))*100.0 if tot>0 else 0.0
        avg= int(round(dur_sum[fl]/float(dur_n[fl]))) if dur_n[fl]>0 else 0
        rows.append((fl, fin, fai, f"{sr:.1f}", avg))
    rows.sort(key=lambda x:(-x[1], x[0]))
    save_csv(os.path.join(args.out_dir, "flows.csv"),
             ["flow","finishes","fails","success_rate_pct","avg_duration_s"], rows)

    save_csv(os.path.join(args.out_dir, "daily.csv"),
             ["date","finishes"], [(d.strftime("%Y-%m-%d"), c) for d,c in sorted(daily.items(), key=lambda x:x[0])])

    # Charts
    charts = {}
    if events:
        save_bar(os.path.join(assets, "events.png"),
                 [k for k,_ in sorted(events.items())],[v for _,v in sorted(events.items())],
                 "Eventos (flow-batch)", "evento", "contagem")
        charts["events"]="report_assets/events.png"

    top_flows = rows[:15]
    if top_flows:
        save_bar(os.path.join(assets, "top_flows.png"),
                 [r[0] for r in top_flows], [r[1] for r in top_flows],
                 "Top flows (finishes)", "flow", "finishes")
        charts["top_flows"]="report_assets/top_flows.png"

    if daily:
        ds=sorted(daily.items(), key=lambda x:x[0])
        save_line(os.path.join(assets, "daily.png"),
                  list(range(len(ds))), [c for _,c in ds],
                  "Série diária (finishes)", "dia (ordem)", "finishes")
        charts["daily"]="report_assets/daily.png"

    # HTML
    style=("body{font-family:system-ui,-apple-system,Segoe UI,Roboto;max-width:1080px;margin:20px auto;padding:0 16px;}"
           ".card{border:1px solid #ddd;border-radius:12px;padding:16px;margin:16px 0;box-shadow:0 1px 3px rgba(0,0,0,.05);}"
           "img{max-width:100%;height:auto;display:block;margin:8px 0}"
           "table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:6px;text-align:left}th{background:#f8f8f8}")
    html=[]
    html.append("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>")
    html.append("<title>FlowBatch — Report</title>")
    html.append(f"<style>{style}</style></head><body>")
    html.append("<h1>FlowBatch — Report</h1>")
    def card_table(title, headers, rows):
        html.append(f"<div class='card'><h2>{title}</h2><table><thead><tr>" + "".join(f"<th>{h}</th>" for h in headers) + "</tr></thead><tbody>")
        for r in rows:
            html.append("<tr>" + "".join(f"<td>{str(x)}</td>" for x in r) + "</tr>")
        html.append("</tbody></table></div>")
    # charts
    for key,label in [("events","Eventos"),("top_flows","Top flows"),("daily","Série diária")]:
        if key in charts:
            html.append(f"<div class='card'><h2>{label}</h2><img src='{charts[key]}' alt='{label}'></div>")
    # tables
    ev_rows = sorted(events.items(), key=lambda x:x[0])
    card_table("Eventos", ["evento","contagem"], ev_rows)
    card_table("Flows", ["flow","finishes","fails","success_rate %","avg_duration s"], rows)
    card_table("Série diária (finishes)", ["dia","finishes"], [(d.strftime("%Y-%m-%d"), c) for d,c in sorted(daily.items(), key=lambda x:x[0])])
    html.append("</body></html>")
    with open(os.path.join(args.out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write("\n".join(html))
    print("[OK] Relatório agregado em:", os.path.join(args.out_dir, "index.html"))

if __name__ == "__main__":
    main()
