#!/usr/bin/env python3
"""
gemx-stats-md.py — Exporta métricas de audit JSONL para Markdown.

Uso:
  python3 gemx-stats-md.py [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--logdir DIR] [--out FILE.md]

Saída padrão: imprime Markdown no stdout se --out não for passado.
"""
import os, sys, json, argparse, datetime, glob
from collections import defaultdict, Counter

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", type=str, default=None)
    ap.add_argument("--until", type=str, default=None)
    ap.add_argument("--logdir", type=str, default=os.path.expanduser("~/.config/gemx/logs"))
    ap.add_argument("--out", type=str, default=None)
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

def main():
    args = parse_args()
    since = parse_date(args.since) if args.since else None
    until = parse_date(args.until) if args.until else None

    events = Counter()
    cmd_finish = Counter()
    model_finish = Counter()
    starts = defaultdict(list)
    dur_sum = Counter()
    dur_n = Counter()
    daily_finish = Counter()

    for dt, obj in iter_logs(args.logdir, since, until):
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

    md = []
    md.append(f"# Gemini Megapack — Relatório (período: {args.since or '-'} a {args.until or '-'})\n")

    def table(headers, rows):
        out = []
        out.append("| " + " | ".join(headers) + " |")
        out.append("| " + " | ".join(['---']*len(headers)) + " |")
        for r in rows:
            out.append("| " + " | ".join(str(x) for x in r) + " |")
        return "\n".join(out)

    # Eventos
    ev_rows = sorted(events.items(), key=lambda x: x[0])
    md.append("## Eventos")
    md.append(table(["evento","contagem"], ev_rows))

    # Top comandos
    md.append("\n## Top comandos (finish)")
    cmds = cmd_finish.most_common(20)
    md.append(table(["comando","contagem"], cmds))

    # Modelos
    md.append("\n## Modelos utilizados")
    models = model_finish.most_common()
    md.append(table(["modelo","contagem"], models))

    # Duração média por comando
    md.append("\n## Duração média por comando (s)")
    dur_items = []
    for cmd in dur_n:
        avg = int(round(dur_sum[cmd]/max(1,dur_n[cmd])))
        dur_items.append((cmd, dur_n[cmd], avg))
    dur_items.sort(key=lambda x: x[2], reverse=True)
    md.append(table(["comando","n","avg (s)"], dur_items))

    # Série diária
    md.append("\n## Série diária (finish)")
    day_rows = sorted([(d.strftime("%Y-%m-%d"), c) for d,c in daily_finish.items()], key=lambda x:x[0])
    md.append(table(["dia","finishes"], day_rows))

    out = "\n".join(md) + "\n"
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out)
        print("[OK] Markdown salvo em:", args.out)
    else:
        sys.stdout.write(out)

if __name__ == "__main__":
    main()
