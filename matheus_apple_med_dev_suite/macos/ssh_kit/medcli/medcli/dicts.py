import os, sqlite3, csv, typer, json, pathlib
from rich import print

app = typer.Typer(help="Dictionary updater: LOINC/RxNorm/SNOMED scaffolding into SQLite")

def _db(path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return sqlite3.connect(path)

@app.command("init")
def init(db: str = typer.Option("./med-dicts.sqlite", help="sqlite path")):
    con = _db(db); cur = con.cursor()
    cur.executescript("""
    CREATE TABLE IF NOT EXISTS loinc(code TEXT PRIMARY KEY, long_name TEXT, component TEXT, property TEXT, time_aspct TEXT, system TEXT, scale_typ TEXT, method_typ TEXT);
    CREATE TABLE IF NOT EXISTS rxnorm(rxcui INTEGER PRIMARY KEY, name TEXT, tty TEXT);
    CREATE TABLE IF NOT EXISTS snomed(concept_id TEXT PRIMARY KEY, fsn TEXT);
    """)
    con.commit(); con.close()
    print(f"[OK] initialized {db}")

@app.command("import-loinc")
def import_loinc(csv_path: str = typer.Argument(...), db: str = typer.Option("./med-dicts.sqlite")):
    """Importe LOINC from CSV (download from loinc.org) — honors their license terms."""
    con = _db(db); cur = con.cursor()
    cur.execute("DELETE FROM loinc")
    with open(csv_path, "r", encoding="utf-8", errors="ignore") as f:
        r = csv.DictReader(f)
        rows = [(row.get("LOINC_NUM"), row.get("LONG_COMMON_NAME"), row.get("COMPONENT"), row.get("PROPERTY"),
                 row.get("TIME_ASPCT"), row.get("SYSTEM"), row.get("SCALE_TYP"), row.get("METHOD_TYP")) for row in r]
    cur.executemany("INSERT OR REPLACE INTO loinc VALUES (?,?,?,?,?,?,?,?)", rows)
    con.commit(); con.close(); print(f"[OK] {len(rows)} LOINC rows -> {db}")

@app.command("import-rxnorm")
def import_rxnorm(csv_path: str = typer.Argument(...), db: str = typer.Option("./med-dicts.sqlite")):
    """Import minimal RxNorm (CSV exported externally)."""
    con = _db(db); cur = con.cursor()
    cur.execute("DELETE FROM rxnorm")
    with open(csv_path, "r", encoding="utf-8") as f:
        r = csv.DictReader(f)
        rows = [(int(row.get("RXCUI")), row.get("STR"), row.get("TTY")) for row in r if row.get("RXCUI")]
    cur.executemany("INSERT OR REPLACE INTO rxnorm VALUES (?,?,?)", rows)
    con.commit(); con.close(); print(f"[OK] {len(rows)} RxNorm rows -> {db}")

@app.command("import-snomed")
def import_snomed(csv_path: str = typer.Argument(...), db: str = typer.Option("./med-dicts.sqlite")):
    """Import SNOMED concepts from a CSV you prepared (respect licensing in your jurisdiction)."""
    con = _db(db); cur = con.cursor()
    cur.execute("DELETE FROM snomed")
    with open(csv_path, "r", encoding="utf-8") as f:
        r = csv.DictReader(f)
        rows = [(row.get("id"), row.get("fsn")) for row in r if row.get("id")]
    cur.executemany("INSERT OR REPLACE INTO snomed VALUES (?,?)", rows)
    con.commit(); con.close(); print(f"[OK] {len(rows)} SNOMED rows -> {db}")

@app.command("lookup")
def lookup(term: str = typer.Argument(...), db: str = typer.Option("./med-dicts.sqlite")):
    """Search across dictionaries (LIKE)."""
    con = _db(db); cur = con.cursor()
    cur.row_factory = sqlite3.Row
    out = {"loinc": [], "rxnorm": [], "snomed": []}
    for tbl, cols, txt in [("loinc","code,long_name","long_name"),("rxnorm","rxcui,name,tty","name"),("snomed","concept_id,fsn","fsn")]:
        cur.execute(f"SELECT {cols} FROM {tbl} WHERE {txt} LIKE ?", (f"%{term}%",))
        out[tbl] = [dict(row) for row in cur.fetchall()]
    con.close(); print(out)
