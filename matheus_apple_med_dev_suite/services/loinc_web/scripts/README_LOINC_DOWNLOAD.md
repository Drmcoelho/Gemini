# Como obter o LOINC (oficial)

O conjunto **LOINC** é distribuído pela **Regenstrief Institute** sob termos próprios.  
Para usar este pack, você precisa **aceitar a licença** e baixar os arquivos no site oficial.

- Portal: https://loinc.org/downloads/loinc/
- Após o download, extraia **LoincTableCore.csv** (ou equivalente) e aponte para ele no importador:

```bash
python scripts/loinc_import.py --csv /caminho/para/LoincTableCore.csv --db ./data/loinc.sqlite
```

> Este repositório **não** inclui dados LOINC — apenas o **importador** e o **schema**.
> Respeite a licença e os termos de uso da Regenstrief.
