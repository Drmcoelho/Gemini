#!/usr/bin/env bash
# plugins.d/omnifocus_task.sh — cria tarefa no OmniFocus (macOS)
# Requer: osascript (AppleScript)
set -euo pipefail
TITLE="${1:-Tarefa Gemini}"
NOTE="${2:-}"
PROJECT="${3:-}"   # opcional
TAGS="${4:-}"      # separados por vírgula
DEFER="${5:-}"     # ex.: 2025-09-20 09:00
DUE="${6:-}"       # ex.: 2025-09-21 18:00

if ! command -v osascript >/dev/null 2>&1; then
  echo "[OF] osascript não disponível; este plugin só funciona no macOS."
  exit 2
fi

# Constrói AppleScript dinamicamente
read -r -d '' SCRIPT <<'OSA' || true
on run argv
  set _title to item 1 of argv
  set _note  to item 2 of argv
  set _proj  to item 3 of argv
  set _tags  to item 4 of argv
  set _defer to item 5 of argv
  set _due   to item 6 of argv
  tell application "OmniFocus"
    tell default document
      set _task to make new inbox task with properties {name:_title, note:_note}
      if _proj is not "" then
        try
          set p to project _proj
          set container of _task to p
        end try
      end if
      if _tags is not "" then
        set AppleScript's text item delimiters to ","
        set arr to every text item of _tags
        repeat with t in arr
          set tagName to contents of t
          try
            set tg to tag tagName
            add tg to tags of _task
          end try
        end repeat
      end if
      if _defer is not "" then set defer date of _task to date _defer
      if _due is not "" then set due date of _task to date _due
    end tell
  end tell
end run
OSA

osascript -e "$SCRIPT" "$TITLE" "$NOTE" "$PROJECT" "$TAGS" "$DEFER" "$DUE"
echo "[OF] Tarefa criada."
