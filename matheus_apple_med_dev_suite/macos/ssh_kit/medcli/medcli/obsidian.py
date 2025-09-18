import os, json, datetime as dt, typing as t
import httpx, typer, pandas as pd
from rich import print

app = typer.Typer(help="Obsidian bridge — render FHIR resources to Markdown notes")

def _client(): return httpx.Client(timeout=30.0)

def _md_path(vault: str, *parts: str) -> str:
    path = os.path.join(vault, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path

def _write(path: str, text: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

@app.command("patient")
def patient(base: str = typer.Option(..., help="FHIR base URL"),
            pid: str = typer.Option(..., help="Patient ID (e.g., 123)"),
            vault: str = typer.Option(..., help="Obsidian vault path"),
            section: str = typer.Option("Patients", help="Folder inside vault"),
            include_obs: bool = typer.Option(True, help="Include Observations"),
            include_cond: bool = typer.Option(True, help="Include Conditions")):
    """Render a Patient summary and related Observations/Conditions into Obsidian Markdown."""
    with _client() as c:
        # patient
        pr = c.get(f"{base.rstrip('/')}/Patient/{pid}", headers={"Accept":"application/fhir+json"})
        pr.raise_for_status(); patient = pr.json()
        name = " ".join([patient.get("name",[{}])[0].get("given",[""])[0], patient.get("name",[{}])[0].get("family","")]).strip() or f"Patient-{pid}"

        today = dt.date.today().isoformat()
        title = f"{name} — {pid}"
        header = f"---\ntitle: {title}\npatient_id: {pid}\ndate: {today}\n---\n\n# {title}\n"
        path = _md_path(vault, section, f"{title}.md")
        _write(path, header)
        print(f"[OK] wrote {path}")

        # observations
        if include_obs:
            orq = c.get(f"{base.rstrip('/')}/Observation", params={"subject": f"Patient/{pid}", "_count":"100"},
                        headers={"Accept":"application/fhir+json"})
            orq.raise_for_status()
            bundle = orq.json()
            rows = []
            for e in bundle.get("entry", []):
                o = e.get("resource", {})
                code = (o.get("code", {}).get("coding", [{}])[0].get("code",""),
                        o.get("code", {}).get("coding", [{}])[0].get("display",""))
                val = ""
                if "valueQuantity" in o:
                    vq = o["valueQuantity"]; val = f"{vq.get('value','')} {vq.get('unit','')}"
                eff = o.get("effectiveDateTime", o.get("issued",""))
                rows.append([eff, code[0], code[1], val])
            if rows:
                md = ["\n## Observations\n", "| when | code | display | value |", "|---|---|---|---|"]
                for r in sorted(rows):
                    md.append(f"| {r[0]} | {r[1]} | {r[2].replace('|','\\|')} | {r[3]} |")
                with open(path, "a", encoding="utf-8") as f: f.write("\n".join(md))

        # conditions
        if include_cond:
            crq = c.get(f"{base.rstrip('/')}/Condition", params={"subject": f"Patient/{pid}", "_count":"100"},
                        headers={"Accept":"application/fhir+json"})
            crq.raise_for_status()
            bundle = crq.json()
            rows = []
            for e in bundle.get("entry", []):
                o = e.get("resource", {})
                code = (o.get("code", {}).get("coding", [{}])[0].get("code",""),
                        o.get("code", {}).get("coding", [{}])[0].get("display",""))
                onset = o.get("onsetDateTime","")
                rows.append([onset, code[0], code[1]])
            if rows:
                md = ["\n## Conditions\n", "| onset | code | display |", "|---|---|---|"]
                for r in sorted(rows):
                    md.append(f"| {r[0]} | {r[1]} | {r[2].replace('|','\\|')} |")
                with open(path, "a", encoding="utf-8") as f: f.write("\n".join(md))
