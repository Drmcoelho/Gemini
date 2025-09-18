import os, json, typing as t
import httpx, typer
from rich import print
from pydantic import BaseModel

app = typer.Typer(help="FHIR client (R4) via HTTP")

def _client(timeout=20.0):
    return httpx.Client(timeout=timeout)

@app.command("get")
def get(base: str = typer.Argument(..., help="FHIR base, e.g. https://hapi.fhir.org/baseR4"),
        path: str = typer.Argument(..., help="resource path, e.g. Patient/123 or Observation?code=..."),
        pretty: bool = typer.Option(True, "--pretty/--no-pretty")):
    with _client() as c:
        r = c.get(f"{base.rstrip('/')}/{path.lstrip('/')}",
                  headers={"Accept":"application/fhir+json"})
    if r.status_code >= 400:
        typer.echo(f"[ERR] {r.status_code}: {r.text}", err=True)
        raise typer.Exit(1)
    data = r.json()
    typer.echo(json.dumps(data, indent=2 if pretty else None))
