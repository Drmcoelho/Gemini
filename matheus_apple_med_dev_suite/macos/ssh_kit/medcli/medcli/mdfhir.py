import os, re, json, typing as t
import httpx, typer, yaml
from rich import print

app = typer.Typer(help="Minimal MD<->FHIR sync (CarePlan/ServiceRequest via frontmatter)")

def _client(): return httpx.Client(timeout=30.0)

def _frontmatter(text: str) -> t.Tuple[dict, str]:
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, flags=re.S)
    if not m: return {}, text
    fm = yaml.safe_load(m.group(1)) or {}
    return fm, m.group(2)

@app.command("md2fhir")
def md2fhir(md_path: str = typer.Argument(..., help="Markdown with frontmatter"),
            base: str = typer.Option(..., help="FHIR base"),
            patient: str = typer.Option(..., help="Patient ID")):
    """Create/Update simple CarePlan/ServiceRequest from Markdown frontmatter sections:
    frontmatter example:
    ---
    careplan:
      title: "Sepsis bundle"
      notes: "48h bundle"
      activities:
        - "Fluid resuscitation"
        - "Lactate monitoring"
    orders:
      - code: "LAB:LACTATE"
        text: "Arterial lactate"
      - code: "IMG:CHEST_XRAY"
        text: "CXR AP"
    ---
    """
    with open(md_path, "r", encoding="utf-8") as f:
        raw = f.read()
    fm, body = _frontmatter(raw)
    with _client() as c:
        if "careplan" in fm:
            cp = fm["careplan"]
            res = {
                "resourceType": "CarePlan",
                "status": "active",
                "intent": "plan",
                "title": cp.get("title") or "Plan",
                "description": cp.get("notes",""),
                "subject": {"reference": f"Patient/{patient}"},
                "activity": [{"detail":{"kind":"ServiceRequest","description":a}} for a in cp.get("activities",[])]
            }
            r = c.post(f"{base.rstrip('/')}/CarePlan", json=res, headers={"Content-Type":"application/fhir+json"})
            r.raise_for_status(); print({"CarePlan": r.json().get("id")})
        if "orders" in fm:
            created = []
            for o in fm["orders"]:
                sr = {
                    "resourceType":"ServiceRequest",
                    "status":"active","intent":"order",
                    "code":{"text":o.get("text",o.get("code",""))},
                    "subject":{"reference": f"Patient/{patient}"}
                }
                r = c.post(f"{base.rstrip('/')}/ServiceRequest", json=sr, headers={"Content-Type":"application/fhir+json"})
                r.raise_for_status(); created.append(r.json().get("id"))
            print({"ServiceRequest": created})

@app.command("fhir2md")
def fhir2md(base: str = typer.Option(...), patient: str = typer.Option(...), out_md: str = typer.Option("Plan.md")):
    """Read CarePlans and ServiceRequests for a patient and emit a Markdown summary with frontmatter."""
    with _client() as c:
        cps = c.get(f"{base.rstrip('/')}/CarePlan", params={"subject": f"Patient/{patient}"}, headers={"Accept":"application/fhir+json"}).json()
        srs = c.get(f"{base.rstrip('/')}/ServiceRequest", params={"subject": f"Patient/{patient}"}, headers={"Accept":"application/fhir+json"}).json()

    careplan = {"title":"","notes":"","activities":[]}
    if cps.get("entry"):
        cp = cps["entry"][0]["resource"]
        careplan["title"] = cp.get("title","")
        careplan["notes"] = cp.get("description","")
        careplan["activities"] = [a.get("detail",{}).get("description","") for a in cp.get("activity",[])]

    orders = []
    for e in srs.get("entry",[]):
        r = e["resource"]; orders.append({"code":"", "text": r.get("code",{}).get("text","")})

    fm = {"careplan": careplan, "orders": orders}
    doc = f"---\n{yaml.safe_dump(fm, sort_keys=False)}---\n\n# Plan for Patient {patient}\n"
    with open(out_md,"w",encoding="utf-8") as f: f.write(doc)
    print(f"[OK] wrote {out_md}")
