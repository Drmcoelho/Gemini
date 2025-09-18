#!/usr/bin/env bash
# doctor.sh — Verificações do ambiente Gemini Megapack
ok=1
say(){ echo "[DOCTOR] $*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

say "Shell: $SHELL"
say "OS: $(uname -a 2>/dev/null || echo unknown)"

for b in gemini gmini jq yq direnv npm node; do
  if have "$b"; then
    say "OK: $b -> $($b --version 2>/dev/null | head -n1)"
  else
    say "MISS: $b (não é crítico se não usado)"
  fi
done

# Check FORCE_MODEL
if [ -n "${GEMX_FORCE_MODEL:-}" ]; then
  say "GEMX_FORCE_MODEL=$GEMX_FORCE_MODEL"
else
  say "GEMX_FORCE_MODEL não setado (o wrapper define default interno gemini-2.5-pro)."
fi

# Direnv status
if have direnv; then
  if [ -n "${DIRENV_DIR:-}" ]; then
    say "direnv ATIVO para este diretório."
  else
    say "direnv NÃO ativado; entre novamente no diretório ou rode 'direnv allow .'"
  fi
fi

# Quick whoami
if have gemini; then
  say "Testando 'gemini whoami' (pode abrir navegador na primeira vez)..."
  timeout 5 gemini whoami >/dev/null 2>&1 || say "whoami indisponível ou não logado (ok se primeira execução)."
fi

say "Diagnóstico concluído."
