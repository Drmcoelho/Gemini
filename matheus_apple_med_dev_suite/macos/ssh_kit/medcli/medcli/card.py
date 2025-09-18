import json, typer, datetime as dt
from rich import print

app = typer.Typer(help="Markdown cards (copy/paste to notes/EMR)")

def _md_escape(s: str) -> str:
    return s.replace("|","\\|")

@app.command("drug")
def drug_card(name: str = typer.Argument(..., help="Drug name to search"),
              rxcui: int = typer.Option(None, help="Optional known RxCUI"),
              source: str = typer.Option("openfda", help="openfda|rxnorm"),
              out: str = typer.Option("-", help="- for stdout or file path")):
    """Produce a Markdown card with basic info (brand/generic, form/route) and interaction handle."""
    import httpx, urllib.parse as up
    generic = name
    brand = ""
    props = {}
    if rxcui:
        j = httpx.get(f"https://rxnav.nlm.nih.gov/REST/rxcui/{rxcui}/properties.json", timeout=20).json()
        props = j.get("properties", {})
        generic = props.get("name", generic)
    else:
        j = httpx.get(f"https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term={up.quote(name)}", timeout=20).json()
        cand = (j.get("approximateGroup", {}).get("candidate",[]) or [{}])[0]
        rxcui = int(cand.get("rxcui", 0) or 0)

    title = f"{generic} (RxCUI: {rxcui})" if rxcui else generic
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    md = [f"---",
          f"title: {title}",
          f"created: {now}",
          f"source: rxnav/openfda",
          f"---",
          f"",
          f"# {title}",
          f"",
          f"- Lookup: https://rxnav.nlm.nih.gov/REST/rxcui/{rxcui}/properties",
          f"- Interactions: https://rxnav.nlm.nih.gov/REST/interaction/interaction.json?rxcui={rxcui}",
          f"",
          f"## Summary",
          f"- Generic: `{generic}`",
          ]
    out_text = "\n".join(md)
    if out == "-":
        print(out_text)
    else:
        with open(out, "w", encoding="utf-8") as f:
            f.write(out_text)
        print(f"[OK] wrote {out}")
