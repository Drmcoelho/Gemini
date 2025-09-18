# LOINC Web — FastAPI + SQLite
FROM python:3.11-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# System deps for SQLite/FTS are included in Python image; add curl for healthchecks.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app /app
COPY scripts/loinc_import.py /usr/local/bin/loinc_import.py

# Data volume
VOLUME ["/data"]

EXPOSE 8080
CMD ["bash", "run.sh"]
