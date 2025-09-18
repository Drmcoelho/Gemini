import os, json, typing as t, datetime as dt
import httpx, typer
from rich import print

# We use matplotlib without specifying styles or colors.
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

app = typer.Typer(help="Plot utilities (FHIR Observations -> PNG)")

def _client(): return httpx.Client(timeout=30.0)

@app.command("obs")
def plot_obs(base: str = typer.Option(..., help="FHIR base URL"),
             patient: str = typer.Option(..., help="Patient ID"),
             code: str = typer.Option(..., help="LOINC code or code display"),
             out_png: str = typer.Option("obs.png", help="Output PNG path"),
             title: str = typer.Option("", help="Optional chart title")):
    """Fetch Observations for a patient filtered by `code` and plot value over time."""
    with _client() as c:
        params = {"subject": f"Patient/{patient}", "_count":"200"}
        r = c.get(f"{base.rstrip('/')}/Observation", params=params, headers={"Accept":"application/fhir+json"})
        r.raise_for_status(); bundle = r.json()

    xs, ys = [], []
    unit = ""
    for e in bundle.get("entry", []):
        o = e.get("resource", {})
        coding = (o.get("code",{}).get("coding",[{}])[0])
        ccode = str(coding.get("code","")).lower()
        cdisp = str(coding.get("display","")).lower()
        if not (code.lower() in ccode or code.lower() in cdisp):
            continue
        when = o.get("effectiveDateTime") or o.get("issued")
        if not when: 
            continue
        x = dt.datetime.fromisoformat(when.replace("Z","+00:00"))
        y = None
        if "valueQuantity" in o:
            vq = o["valueQuantity"]
            try:
                y = float(vq.get("value"))
                unit = vq.get("unit") or unit
            except Exception:
                y = None
        if y is not None:
            xs.append(x); ys.append(y)

    if not xs:
        typer.echo("[WARN] no matching observations found"); raise typer.Exit(1)

    # Plot (single line)
    plt.figure()              # single, no style, no color set
    plt.plot(xs, ys, marker="o")
    plt.xlabel("time")
    ylabel = f"value {('('+unit+')') if unit else ''}"
    plt.ylabel(ylabel)
    if title:
        plt.title(title)
    plt.grid(True, which="both", axis="both")
    plt.tight_layout()
    plt.savefig(out_png, dpi=180)
    print(f"[OK] wrote {out_png}")
