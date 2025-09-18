#!/usr/bin/env python3
"""
gemx-stats-html.py — "Grafana-lite" estático para os logs JSONL do Gemini Megapack.

- Lê ~/.config/gemx/logs/audit-*.jsonl
- Filtros: --since YYYY-MM-DD, --until YYYY-MM-DD
- Saída: diretório (--out-dir, default ./gemx_report) com index.html e PNGs em report_assets/
- Requisitos: Python 3, matplotlib; pandas não é necessário.

Restrições: usar matplotlib puro, um gráfico por figura, sem especificar cores.
"""
import os, sys, json, argparse, datetime, glob
from collections import defaultdict, Counter

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", type=str, default=None)
    ap.add_argument("--until", type=str, default=None)
    ap.add_argument("--logdir", type=str, default=os.path.expanduser("~/.config/gemx/logs"))
    ap.add_argument("--out-dir", type=str, default="./gemx_report")
    ap.add_argument("--batch", type=str, default=None,
                    help="Lista de intervalos start:end separados por ponto e vírgula. Ex.: 2025-08-01:2025-08-31;2025-09-01:2025-09-18")
    ap.add_argument("--batch-monthly", action="store_true",
                    help="Gera 1 relatório por mês encontrado nos logs (YYYY-MM).")
    return ap.parse_args()

def parse_date(s):
    return datetime.datetime.strptime(s, "%Y-%m-%d").date()

def iter_logs(logdir, since=None, until=None):
    files = sorted(glob.glob(os.path.join(logdir, "audit-*.jsonl")))
    for f in files:
        with open(f, "r", encoding="utf-8") as fh:
            for line in fh:
                line=line.strip()
                if not line: 
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                ts = obj.get("ts")
                if not ts:
                    continue
                try:
                    dt = datetime.datetime.fromisoformat(ts.replace("Z","+00:00"))
                except Exception:
                    continue
                d = dt.date()
                if since and d < since:
                    continue
                if until and d > until:
                    continue
                yield dt, obj

def ensure_dir(p):
    os.makedirs(p, exist_ok=True)

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

def build_once(since, until, logdir, out_dir):
    since = parse_date(since) if since else None
    until = parse_date(until) if until else None
    ensure_dir(out_dir)
    assets = os.path.join(out_dir, "report_assets")
    ensure_dir(assets)

    events = Counter()
    cmd_finish = Counter()
    model_finish = Counter()
    starts = defaultdict(list)
    dur_sum = Counter()
    dur_n = Counter()
    daily_finish = Counter()

    for dt, obj in iter_logs(logdir, since, until):
        ev = obj.get("event")
        events[ev]+=1
        argv = obj.get("argv") or []
        cmd = argv[0] if argv else "(none)"
        if ev == "start":
            sig = (obj.get("bin",""), json.dumps(argv, sort_keys=True))
            starts[sig].append(dt)
        elif ev == "finish":
            sig = (obj.get("bin",""), json.dumps(argv, sort_keys=True))
            if starts[sig]:
                t0 = starts[sig].pop(0)
                dur = (dt - t0).total_seconds()
                dur_sum[cmd]+=dur
                dur_n[cmd]+=1
            cmd_finish[cmd]+=1
            model_finish[obj.get("model","unknown")]+=1
            daily_finish[dt.date()]+=1

    events_items = sorted(events.items(), key=lambda x: x[0])
    cmds_items = cmd_finish.most_common(15)
    models_items = model_finish.most_common()
    dur_items = []
    for cmd in dur_n:
        avg = dur_sum[cmd]/max(1,dur_n[cmd])
        dur_items.append((cmd, dur_n[cmd], int(round(avg))))
    dur_items.sort(key=lambda x: x[2], reverse=True)
    days = sorted(daily_finish.items(), key=lambda x:x[0])
    day_labels = [d.strftime("%Y-%m-%d") for d,_ in days]
    day_values = [c for _,c in days]

    charts = {}
    try:
        if events_items:
            save_bar(os.path.join(assets, "events.png"),
                    [k for k,_ in events_items], [v for _,v in events_items],
                    "Eventos", "evento", "contagem")
            charts["events"]="report_assets/events.png"
        if cmds_items:
            save_bar(os.path.join(assets, "top_commands.png"),
                    [k for k,_ in cmds_items], [v for _,v in cmds_items],
                    "Top comandos (finish)", "comando", "contagem")
            charts["top_commands"]="report_assets/top_commands.png"
        if models_items:
            save_bar(os.path.join(assets, "models.png"),
                    [k for k,_ in models_items], [v for _,v in models_items],
                    "Modelos utilizados", "modelo", "contagem")
            charts["models"]="report_assets/models.png"
        if dur_items:
            save_bar(os.path.join(assets, "durations.png"),
                    [k for k,_,_ in dur_items], [v for _,_,v in dur_items],
                    "Duração média por comando (s)", "comando", "segundos")
            charts["durations"]="report_assets/durations.png"
        if day_labels:
            save_line(os.path.join(assets, "daily.png"),
                    list(range(len(day_labels))), day_values,
                    "Série diária (finish)", "dia (ordem)", "finishes")
            charts["daily"]="report_assets/daily.png"
    except Exception as e:
        print("[WARN] Erro ao gerar gráficos (matplotlib ausente?):", e)

    # HTML
    style = (
        "body{font-family:system-ui,-apple-system,Segoe UI,Roboto;max-width:1080px;margin:20px auto;padding:0 16px;}"
        "h1{margin-top:0}"
        ".card{border:1px solid #ddd;border-radius:12px;padding:16px;margin:16px 0;box-shadow:0 1px 3px rgba(0,0,0,.05);}"
        "img{max-width:100%;height:auto;display:block;margin:8px 0}"
        "table{border-collapse:collapse;width:100%}"
        "th,td{border:1px solid #ddd;padding:6px;text-align:left}"
        "th{background:#f8f8f8}"
        "code{background:#f3f3f3;padding:2px 4px;border-radius:4px}"
    )
    html = []
    html.append("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>")
    html.append("<title>Gemini Megapack — Dashboard</title>")
    html.append(f"<style>{style}</style>")
    html.append("</head><body>")
    html.append("<h1>Gemini Megapack — Dashboard</h1>")
    html.append(f"<div class='card'><b>Período:</b> {since.isoformat() if since else None or '-'} a {until.isoformat() if until else None or '-'} &mdash; <b>Logs:</b> {logdir}</div>")

    def table(title, headers, rows):
        html.append(f"<div class='card'><h2>{title}</h2><table><thead><tr>" + "".join(f"<th>{h}</th>" for h in headers) + "</tr></thead><tbody>")
        for r in rows:
            html.append("<tr>" + "".join(f"<td>{str(x)}</td>" for x in r) + "</tr>")
        html.append("</tbody></table></div>")

    for key, label in [("events","Eventos"),("top_commands","Top comandos"),("models","Modelos"),("durations","Duração média por comando"),("daily","Série diária")]:
        if key in charts:
            html.append(f"<div class='card'><h2>{label}</h2><img src='{charts[key]}' alt='{label}'></div>")

    table("Eventos", ["evento","contagem"], events_items)
    table("Top comandos (finish)", ["comando","contagem"], cmds_items)
    table("Modelos utilizados", ["modelo","contagem"], models_items)
    table("Duração média por comando (s)", ["comando","n","avg (s)"], dur_items)
    table("Série diária (finish)", ["dia","finishes"], [(d.strftime("%Y-%m-%d"), c) for d,c in days])

    html.append("<div class='card'><b>Gerado por:</b> gemx-stats-html.py</div>")
    html.append("</body></html>")
    out_html = os.path.join(out_dir, "index.html")
    with open(out_html, "w", encoding="utf-8") as fh:
        fh.write("\n".join(html))
    print("[OK] Relatório gerado em:", out_html)

if __name__ == "__main__":
    main()
