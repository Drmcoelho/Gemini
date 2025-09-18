# medcli (pipx-ready)

## Instalação (local)
```bash
cd medcli
python3 -m pip install --upgrade build pipx
pipx install .    # cria um venv isolado com o comando "med"
# ou
pipx install --editable .
```

## Uso
```bash
med fhir get https://hapi.fhir.org/baseR4 "Patient?_count=3"
med openfda query label 'openfda.brand_name:"metformin"' --limit 3
med rxnorm rxcui "amoxicillin"
med ctgov search "query.term=sepsis&page.size=5&fields=BriefTitle,OverallStatus"
med card drug "metformin" --out Drug-metformin.md
med obsidian patient --base https://hapi.fhir.org/baseR4 --pid 123 --vault "$HOME/Obsidian/MedVault"
med dicts init
med dicts import-loinc ~/Downloads/LoincTableCore.csv
med dicts lookup "glucose"
```
