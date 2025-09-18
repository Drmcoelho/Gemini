import typer
from . import fhir, openfda, rxnorm, ctgov, obsidian, dicts, card, plots, mdfhir

app = typer.Typer(add_completion=False, help="medcli — FHIR/OpenFDA/RxNorm/CTGov & Obsidian bridge")

app.add_typer(fhir.app, name="fhir")
app.add_typer(openfda.app, name="openfda")
app.add_typer(rxnorm.app, name="rxnorm")
app.add_typer(ctgov.app, name="ctgov")
app.add_typer(obsidian.app, name="obsidian")
app.add_typer(dicts.app, name="dicts")
app.add_typer(card.app, name="card")
app.add_typer(plots.app, name="plots")
app.add_typer(mdfhir.app, name="mdfhir")

if __name__ == "__main__":
    app()
