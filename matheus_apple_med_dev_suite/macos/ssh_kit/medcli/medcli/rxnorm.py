import json, urllib.parse
import httpx, typer
from rich import print

app = typer.Typer(help="RxNav / RxNorm")

@app.command("rxcui")
def rxcui(term: str):
    url = f"https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term={urllib.parse.quote(term)}"
    r = httpx.get(url, timeout=30.0); r.raise_for_status(); print(r.json())

@app.command("properties")
def properties(rxcui: int):
    url = f"https://rxnav.nlm.nih.gov/REST/rxcui/{rxcui}/properties.json"
    r = httpx.get(url, timeout=30.0); r.raise_for_status(); print(r.json())

@app.command("interactions")
def interactions(rxcui: int):
    url = f"https://rxnav.nlm.nih.gov/REST/interaction/interaction.json?rxcui={rxcui}"
    r = httpx.get(url, timeout=30.0); r.raise_for_status(); print(r.json())
