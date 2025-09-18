import json, urllib.parse
import httpx, typer
from rich import print

app = typer.Typer(help="OpenFDA (drugs)")

BASE="https://api.fda.gov/drug"

@app.command("query")
def query(endpoint: str = typer.Argument("label", help="label|event|enforcement"),
          search: str = typer.Argument('openfda.brand_name:"aspirin"'),
          limit: int = 5, skip: int = 0):
    url = f"{BASE}/{endpoint}.json?search={urllib.parse.quote(search)}&limit={limit}&skip={skip}"
    r = httpx.get(url, timeout=30.0)
    r.raise_for_status()
    print(r.json())
