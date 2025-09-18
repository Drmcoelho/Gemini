#!/usr/bin/env python3
"""
loinc_import.py — Importa LOINC (CSV) para SQLite com FTS5.
Requer: arquivo CSV oficial (ex.: LoincTableCore.csv) após aceitar a licença no site LOINC.
Uso:
  python loinc_import.py --csv /path/LoincTableCore.csv --db /data/loinc.sqlite
"""
import csv, sqlite3, argparse, os, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="Caminho para LoincTableCore.csv (ou mapeado equivalente)")
    ap.add_argument("--db", default="/data/loinc.sqlite", help="Arquivo SQLite de saída")
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.db) or ".", exist_ok=True)
    conn = sqlite3.connect(args.db)
    cur = conn.cursor()

    cur.executescript("""
    PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS loinc(
      code TEXT PRIMARY KEY,
      long_name TEXT,
      short_name TEXT,
      component TEXT,
      property TEXT,
      time_aspct TEXT,
      system TEXT,
      scale_typ TEXT,
      method_typ TEXT,
      class TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_loinc_name ON loinc(long_name);
    CREATE INDEX IF NOT EXISTS idx_loinc_component ON loinc(component);
    """)

    # Try to ensure FTS5
    try:
        cur.executescript("""
        CREATE VIRTUAL TABLE IF NOT EXISTS loinc_fts
          USING fts5(long_name, component, class, content='loinc', content_rowid='rowid');
        -- Backfill FTS
        INSERT INTO loinc_fts(loinc_fts) VALUES('rebuild');
        """)
        has_fts = True
    except sqlite3.OperationalError:
        has_fts = False
        print("[WARN] FTS5 não disponível. Buscas usarão LIKE.", file=sys.stderr)

    # Clear
    cur.execute("DELETE FROM loinc")

    # Columns expected (core file)
    # LOINC_NUM,LONG_COMMON_NAME,SHORTNAME,COMPONENT,PROPERTY,TIME_ASPCT,SYSTEM,SCALE_TYP,METHOD_TYP,CLASS
    with open(args.csv, newline='', encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        rows = []
        for i, row in enumerate(reader, 1):
            rows.append((
                row.get("LOINC_NUM"), row.get("LONG_COMMON_NAME"), row.get("SHORTNAME"),
                row.get("COMPONENT"), row.get("PROPERTY"), row.get("TIME_ASPCT"),
                row.get("SYSTEM"), row.get("SCALE_TYP"), row.get("METHOD_TYP"), row.get("CLASS")
            ))
            if len(rows) >= 5000:
                cur.executemany("INSERT OR REPLACE INTO loinc VALUES(?,?,?,?,?,?,?,?,?,?)", rows)
                rows.clear()
        if rows:
            cur.executemany("INSERT OR REPLACE INTO loinc VALUES(?,?,?,?,?,?,?,?,?,?)", rows)

    conn.commit()
    if has_fts:
        cur.execute("INSERT INTO loinc_fts(loinc_fts) VALUES('rebuild')")

    conn.commit(); conn.close()
    print("[OK] import concluído:", args.db)

if __name__ == "__main__":
    main()
