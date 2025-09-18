import json
import httpx, typer, urllib.parse as up
from rich import print

app = typer.Typer(help="ClinicalTrials.gov v2")

@app.command("search")
def search(query: str = typer.Argument("query.term=sepsis&page.size=5&fields=BriefTitle,OverallStatus")):
    url = f"https://clinicaltrials.gov/api/v2/studies?{query}"
    r = httpx.get(url, timeout=30.0); r.raise_for_status(); print(r.json())
